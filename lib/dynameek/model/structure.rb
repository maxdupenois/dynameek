module Dynameek
  module Model
    module Structure
      
      def fields
        @fields ||= {}
      end
      
      def hash_key_info
        if(@hash_key.nil?)
          @hash_key = OpenStruct.new
          @hash_key.field = nil
          @hash_key.type = nil
        end
        @hash_key
      end 
      
      def range_info
        if(@range.nil?)
          @range = OpenStruct.new
          @range.field = nil
          @range.type = nil
        end
        @range
      end
      
      def index_table?
        @uses_index_table|| false
      end
      

      def range?
        !range_info.field.nil?
      end
      
      def read_units
        @read_write ||= [10, 5]
        @read_write[0]
      end
      
      def write_units
        @read_write ||= [10, 5]
        @read_write[1]
      end
      
      def read_write(vals)
        @read_write = vals
      end
      
      def multi_column_hash_key_fields
        @multi_column_hash_key_fields ||= []
      end
            
      def multi_column_join
        @multi_column_join ||= "|"
      end
      
      def multi_column_join=(join)
        @multi_column_join =join
      end
      
      def multi_column_hash_key?
        !multi_column_hash_key_fields.empty?
      end
    
      def field fieldname, type
        fieldname = fieldname.to_sym
        type = type.to_sym
        fields[fieldname] = type
        define_method(fieldname.to_s) { read_attribute(fieldname) }
        define_method("#{fieldname.to_s}?") { !read_attribute(fieldname).nil? }
        define_method("#{fieldname.to_s}=") {|value| write_attribute(fieldname, value) }
      end 

      def hash_key fieldname
        fieldname = fieldname.to_sym
        check_field(fieldname)
        hash_key_info.field = fieldname
        hash_key_info.type = fields[fieldname]
        define_method(:hash_key) { read_attribute(fieldname) }
      end

      def multi_column_hash_key fieldnames
        fieldnames = fieldnames.map(&:to_sym)
        fieldnames.each{|f| check_field(f)}
        fieldnames.each {|f| multi_column_hash_key_fields << f}
        fieldname = fieldnames.map(&:to_s).join("_").to_sym
        fields[fieldname] = :string
        define_method(:hash_key) do
          self.class.multi_column_hash_key_fields.reduce([]) do |memo, field|
            memo << attributes[field]
            memo
          end.join(self.class.multi_column_join)
        end
        alias_method fieldname, :hash_key
        hash_key_info.field = fieldname
        hash_key_info.type = :string
      end

      def range fieldname
        fieldname = fieldname.to_sym
        check_field(fieldname)
        range_info.field = fieldname
        range_info.type = fields[fieldname]
        define_method(:range) do
          attributes[self.class.range_info.field]
        end
      end
     
      def aws_item_to_hash(item)
        (item.is_a?(AWS::DynamoDB::Item) || item.is_a?(AWS::DynamoDB::ItemData) ? 
         item.attributes.to_hash : 
         item
        )
      end

      def current_range(key, range_val)
        return nil if !index_table?
        key.join!(multi_column_join) if key.is_a?(Array)
        item = index_table.items.query(
          {
            hash_value: key,
            select: :all,
            range_value: range_val
          }).first
        return 0 if item.nil?
        item_hsh = aws_item_to_hash(item)    
        item_hsh['current_range_val'].to_i 
      end
  
      def use_index_table
        define_method(:act_hash_key) do
          [self.class.convert_to_dynamodb(self.class.hash_key_info.type, hash_key), 
            self.class.multi_column_join,
            self.class.convert_to_dynamodb(self.class.range_info.type, range)].join('')
        end
        field :dynameek_index, :number
        @uses_index_table = true
      end

      def check_field(fieldname)
        raise ("#{fieldname} is not a recognised field") if fields[fieldname].nil?
      end

    end
  end
end

  
