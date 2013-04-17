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
      if self.class.index_table?
        rng = self.class.convert_to_dynamodb(
          self.class.range_info.type, 
          attributes[self.class.range_info.field]
        )
        curr_range = self.class.current_range(hash_key, rng) + 1
        self.class.index_table.batch_write(
          :put => [
            {
              self.class.hash_key_info.field => attribs[self.class.hash_key_info.field],
              self.class.range_info.field => attribs[self.class.range_info.field],
              current_range_val: curr_range
            }    
          ]
        )
        attribs[self.class.hash_key_info.field.to_s+"_"+self.class.range_info.field.to_s] = 
           attribs[self.class.hash_key_info.field].to_s +
           self.class.multi_column_join + 
           attribs[self.class.range_info.field].to_s
        attribs[:dynameek_index] = curr_range
        self.class.table.batch_write(
            :put => [
            attribs
          ]
        )
      else
        self.class.table.batch_write(
            :put => [
            attribs
          ]
        )
      end
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
        if self.class.index_table?
          self.class.table.batch_delete([[act_hash_key, attributes[:dynameek_index]]])
        else
          self.class.table.batch_delete([[hash_key, range_val]])
        end
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
        return nil if(items.entries.size == 0)
        item_to_instance(items.first)
      end
  
      def delete_table

        index_table.delete if dynamo_db.tables[index_table_name].exists?
        table.delete if dynamo_db.tables[table_name].exists?
        while dynamo_db.tables[table_name].exists? && 
              dynamo_db.tables[index_table_name].exists?
          sleep 1
        end
      end
  
      def item_to_instance(item)
        item_hsh = aws_item_to_hash(item)
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
        self.to_s.gsub(/.*?([A-Za-z][A-Za-z0-9]*)$/, '\1')
      end
      
      def index_table_name
        table_name + "_INDEX"
      end

    end
  end
end
