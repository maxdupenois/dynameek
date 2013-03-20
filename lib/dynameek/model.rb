class Dynameek::Model
  extend Dynameek::DynamoDb
  extend Dynameek::ModelStructure
  extend Dynameek::Query
  
  
  
  
  attr_accessor :attributes
  
  
  
  def self.find(hash_key, range_val=nil)
    raise Exception("This has a composite hash with a range, the range val is required") if(range_val.nil? && !@@range.field.nil?)
    #multicolumn
    hash_key = hash_key.join(multi_column_join) if(hash_key.is_a?(Array))

    items = if !range_val.nil?
      range_val = convert_to_dynamodb(range_field.type, range_val)
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
    fields.each do |field, type|
      next if multi_column_hash_key? && field == hash_key_field.field
      instance.send "#{field.to_s}=", convert_from_dynamodb(type, item[field.to_s])
    end
    instance
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
    attribs = self.class.fields.reduce({}) do |memo, (field, type)|
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

  
  def self.table_name
    self.to_s
  end
  
  private
  
  def read_attribute(fieldname)
    @attributes[fieldname]
  end

  def write_attribute(fieldname, value)
    @attributes = {} if(!@attributes) 
    @attributes[fieldname] = value
  end

  
end