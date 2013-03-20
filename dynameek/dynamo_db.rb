module Dynameek
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
        :hash_key => { @@hash_key.field => @@hash_key.type },
        :range_key => { @@range.field => @@range.type == :datetime ? :number : @@range.type }
      )
      puts "Creating table, this may take a few minutes"
      while new_table.status == :creating
        sleep 1
      end
    end
    
    @@table = nil
    @@dynamo_db = nil

    def dynamo_db
      @@dynamo_db = AWS::DynamoDB.new if @@dynamo_db.nil?
      @@dynamo_db
    end

    def table
      build!
      @@table = dynamo_db.tables[table_name] if @@table.nil?
      @@table.load_schema if !@@table.schema_loaded?
      @@table
    end
    
  end
end