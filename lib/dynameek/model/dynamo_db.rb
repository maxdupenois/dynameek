module Dynameek
  module Model
    module DynamoDb
      def convert_from_dynamodb(type, value)
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
      def convert_to_dynamodb(type, value)
        case type
          when :datetime
            value.to_time.to_f
          else
            value
        end
      end
    
      def exists?
        table.exists?
      end
    
      def build!
        return if dynamo_db.tables[table_name].exists?
        new_table = dynamo_db.tables.create(table_name, @@read_write[0], @@read_write[1],
          :hash_key => { hash_key_field.field => hash_key_field.type },
          :range_key => { range_field.field => range_field.type == :datetime ? :number : range_field.type }
        )
        puts "Creating table, this may take a few minutes"
        while new_table.status == :creating
          sleep 1
        end
      end
    
      def dynamo_db
        @dynamo_db ||= AWS::DynamoDB.new 
        @dynamo_db
      end

      def table
        build!
        @table ||= dynamo_db.tables[table_name]
        @table.load_schema if !@table.schema_loaded?
        @table
      end
    
    end
  end
end