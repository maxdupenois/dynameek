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
        opts = {:hash_key => { hash_key_info.field => [:datetime, :integer, :float].include?(hash_key_info.type) ? :number : hash_key_info.type }}
        if range?
          opts[:range_key] = { range_info.field => [:datetime, :integer, :float].include?(range_info.type) ? :number : range_info.type } 
        end
        new_table = dynamo_db.tables.create(table_name, read_units, write_units, opts)
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