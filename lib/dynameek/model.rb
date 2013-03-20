module Dynameek
  module Model
    def self.included(base)
      base.extend ClassMethods
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
      self.class.before_save_callbacks.each{|method| self.send method}
      self.class.table.batch_write(
        :put => [
          attribs
        ]
      )
      self
    end
    
    
    
    def attributes
      @attributes ||= {}
    end
    
    def read_attribute(fieldname)
      attributes[fieldname]
    end

    def write_attribute(fieldname, value)
      attributes[fieldname] = value
    end
    
    def delete
      if self.class.range?
        range_val = self.class.convert_to_dynamodb(self.class.range_info.type, self.send(self.class.range_info.field))
        #Rounding errors can be irritating here so if we have the actual item we'll use it's range_val, nope that makes things worse
        # range_val = dynamo_item.range_value if !dynamo_item.nil?
        # p "TRYING TO DELETE #{[[hash_key, range_val]]}.inspect"
        # p "FINDING THAT THING: #{self.class.find(hash_key, self.send(self.class.range_info.field)).inspect}"
        # p "VIA BATCH GET  #{self.class.table.batch_get(:all, [[hash_key, range_val]]).entries.inspect}"
        self.class.table.batch_delete([[hash_key, range_val]])
      else  
        self.class.table.batch_delete([hash_key])
      end
    end
    
    def dynamo_item
      @dynamo_item ||= nil
    end

    def dynamo_item=(item)
      @dynamo_item = item
    end
  
    module ClassMethods
      include Dynameek::Model::DynamoDb
      include Dynameek::Model::Structure
      include Dynameek::Model::Query
      
  
  
  
      def find(hash_key, range_val=nil)
        raise Exception("This has a composite hash with a range, the range val is required") if(range_val.nil? && range?)
        #multicolumn
        hash_key = hash_key.join(multi_column_join) if(hash_key.is_a?(Array))

        items = if range?
          range_val = convert_to_dynamodb(range_info.type, range_val)
          table.batch_get(:all, [[hash_key, range_val]])
        else  
          table.batch_get(:all, [hash_key])
        end
        # p items.methods - Object.new.methods
        return nil if(items.entries.size == 0)
        item_to_instance(items.first)
    
      end
  
      def delete_table
        table.delete
      end

  
      def item_to_instance(item)
        item_hsh = (item.is_a?(AWS::DynamoDB::Item) || item.is_a?(AWS::DynamoDB::ItemData) ? item.attributes.to_hash : item)
        instance = self.new
        fields.each do |field, type|
          next if multi_column_hash_key? && field == hash_key_info.field
          instance.send "#{field.to_s}=", convert_from_dynamodb(type, item_hsh[field.to_s])
        end
        if item.is_a?(AWS::DynamoDB::Item) || item.is_a?(AWS::DynamoDB::ItemData)
          instance.dynamo_item =  item.is_a?(AWS::DynamoDB::ItemData) ? item.item : item
        end
        instance
      end
  
      
  
      def create(attrib)
        instance = self.new
        attrib.each do |key, val|
          instance.send "#{key.to_s}=", val
        end
        instance.save
      end
  
      def before_save_callbacks
        @before_save_callbacks ||= Set.new
      end
  
      def before_save method
        before_save_callbacks << method.to_sym
      end
  

  
      def table_name
        self.to_s
      end
  

  
    end
  end
end