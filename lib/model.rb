class Dynameek::Model
  @@fields = {}
  @@hash_key = OpenStruct.new
  @@hash_key.field = nil
  @@hash_key.type = nil
  
  @@range = OpenStruct.new
  @@range.field = nil
  @@range.type = nil
  
  @@read_write = [10, 5]
  
  @@multi_column_hash_key_fields = []
  @@multi_column_join = "|"
  
  attr_accessor :attributes
  
  def self.field fieldname, type
    fieldname = as_sym(fieldname)
    type = as_sym(type)
    @@fields[fieldname] = type
    define_method(fieldname.to_s) { read_attribute(fieldname) }
    define_method("#{fieldname.to_s}?") { !read_attribute(fieldname).nil? }
    define_method("#{fieldname.to_s}=") {|value| write_attribute(fieldname, value) }
  end 
  

  
  def self.hash_key fieldname
    fieldname = as_sym(fieldname)
    check_field(fieldname)
    @@hash_key.field = fieldname
    @@hash_key.type = @@fields[fieldname]
    define_method(:hash_key) { read_attribute(fieldname) }
  end
  
  def self.multi_column_join join
    @@multi_column_join = join
  end
  
  def self.multi_column_hash_key fieldnames
    fields = fieldnames.map(&:to_sym)
    fields.each{|f| check_field(f)}
    @@multi_column_hash_key_fields = fields
    fieldname = fieldnames.map(&:to_s).join("_").to_s
    @@fields[fieldname] = :string
    define_method(:hash_key) do 
      @@multi_column_hash_key_fields.reduce([]) do |memo, field|
        memo << attributes[field]
        memo
      end.join(@@multi_column_join)
    end
    alias_method fieldname, :hash_key
    @@hash_key.field = fieldname
    @@hash_key.type = :string
  end
  
  def self.range fieldname
    fieldname = as_sym(fieldname)
    check_field(fieldname)
    @@range.field = fieldname
    @@range.type = @@fields[fieldname]
  end
  
  def self.read_write read, write
    @@read_write = [read, write]
  end
  
  def self.find(hash_key, range_val=nil)
    raise Exception("This has a composite hash with a range, the range val is required") if(range_val.nil? && !@@range.field.nil?)
    #multicolumn
    hash_key = hash_key.join(@@multi_column_join) if(hash_key.is_a?(Array))

    items = if !range_val.nil?
      range_val = convert_to_dynamodb(@@range.type, range_val)
      table.batch_get(:all, [[hash_key, range_val]])
    else
      table.batch_get(:all, [hash_key])
    end
    # p items.methods - Object.new.methods
    return nil if(items.entries.size == 0)
    item_to_instance(items.first)
    
  end
  

  
  def self.item_to_instance(item)
    item = item.attributes if item.is_a?(AWS::DynamoDB::Item)
    instance = self.new
    @@fields.each do |field, type|
      next if !@@multi_column_hash_key_fields.empty? && field == @@hash_key.field
      instance.send "#{field.to_s}=", convert_from_dynamodb(type, item[field.to_s])
    end
    instance
  end
  
  def self.range_query(hash_key, range_start, range_end=nil)
    raise Exception("Range query can only be performed on a composite hash with a range") if(@@range.field.nil?)
    #multicolumn
    range_start_op = :range_greater_than
    range_start_val = range_start
    if range_start.is_a?(Hash)
      range_start_op = range_start[:op]
      range_start_val = range_start[:val]
    end
    range_start_val = convert_to_dynamodb(@@range.type, range_start_val)

    if(!range_end.nil?)
      range_end_op = :range_lte
      range_end_val = range_end
      if range_end.is_a?(Hash)
        range_end_op = range_end[:op]
        range_end_val = range_end[:val]
      end
      range_end_val = convert_to_dynamodb(@@range.type, range_end_val)
    end
    
    hash_key = hash_key.join(@@multi_column_join) if(hash_key.is_a?(Array))
    query_hash = {:hash_value => hash_key}
    query_hash[range_start_op] = range_start_val
    query_hash[range_end_op] = range_end_val if(!range_end.nil?)
    
    table.items.query(
      query_hash
    ).map{|item| item_to_instance(item)}
    
  end
  
  def self.create(attrib)
    instance = self.new
    attrib.each do |key, val|
      instance.send "#{key.to_s}=", val
    end
    instance.save
  end
  
  @@before_save_callbacks = Set.new
  def self.before_save method
    @@before_save_callbacks.add(method.to_sym)  
  end
  
  def save
    attribs = @@fields.reduce({}) do |memo, (field, type)|
      #Always call the read method in case it has been overwritten
      #Note that this is required for the multicolumn key
      val =  self.send field
      val = self.class.convert_to_dynamodb(type, val)
      memo[field] = val
      memo
    end
    @@before_save_callbacks.each{|method| self.send method}
    self.class.table.batch_write(
      :put => [
        attribs
      ]
    )
    self
  end
  

  def self.exists?
    table.exists?
  end
  
  
  def self.build!
    return if dynamo_db.tables[table_name].exists?
    new_table = dynamo_db.tables.create(table_name, @@read_write[0], @@read_write[1],
      :hash_key => { @@hash_key.field => @@hash_key.type },
      :range_key => { @@range.field => @@range.type == :datetime ? :number : @@range.type }
    )
    puts "Creating table, this may take a few minutes"
    while new_table.status == :creating
      sleep 1
    end
  end
  
  def self.table_name
    self.to_s
  end
  
  private
  
  def self.convert_from_dynamodb(type, value)
    case type
      when :integer
        value.to_i
      when :float
        value.to_f
      when :string
        value.to_s
      when :datetime
        Time.at(value).to_datetime
      else
        value
    end
  end
  def self.convert_to_dynamodb(type, value)
    case type
      when :datetime
        value.to_time.to_f
      else
        value
    end
  end
  
  def read_attribute(fieldname)
    @attributes[fieldname]
  end
  
  def write_attribute(fieldname, value)
    @attributes = {} if(!@attributes) 
    @attributes[fieldname] = value
  end
  
  @@table = nil
  @@dynamo_db = nil
  
  def self.dynamo_db
    @@dynamo_db = AWS::DynamoDB.new if @@dynamo_db.nil?
    @@dynamo_db
  end
  
  def self.table
    build!
    @@table = dynamo_db.tables[table_name] if @@table.nil?
    @@table.load_schema if !@@table.schema_loaded?
    @@table
  end
  
  def self.as_sym(val)
    (val.is_a?(Symbol) ? val : val.to_sym)
  end
  
  def self.check_field(fieldname)
    raise Exception("#{fieldname} is not a recognised field") if @@fields[fieldname].nil?
  end

  
end