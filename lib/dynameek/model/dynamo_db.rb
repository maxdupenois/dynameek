module Dynameek
  module Model
    module DynamoDb
      def convert_from_dynamodb(type, value)
        return nil if value.nil?
        case type
          when :integer
            value.to_i
          when :float
            value.to_f
          when :string
            value.to_s
          when :datetime
            Time.at(value).to_datetime
          when :boolean
            value.to_i == 1
          when :binary
            begin 
              Marshal.load(value)
            rescue => e
              puts "[WARNING] Failed to load value #{value}"

            end
          else
            value
        end
      end
      def convert_to_dynamodb(type, value)
        return nil if value.nil?
        case type
          when :datetime
            value.to_time.to_f
          when :binary
            dump_safe(value)
            Marshal.dump(value)
          when :boolean
            value ? 1 : 0
          else
            value
        end
      end
      StackFrame = Struct.new(:current, :index)

      def dump_safe(obj)
        return obj if(!obj.is_a?(Hash) && !obj.is_a?(Array))
        make_safe = lambda do |thing|
          if thing.is_a?(Hash)
            #thing.default_proc = nil
            thing.default = nil
          end
        end
        stack = []
        safe = obj
        make_safe.call(safe)
        stack.push(StackFrame.new(safe, 0))
        
        while(current_frame = stack.pop)
          current = current_frame.current
          index   = current_frame.index
          obj     = current.is_a?(Hash) ? current[current.keys[index]] : current[index]
          make_safe.call(obj) 
          if index - 1 < current.size
            # Re-add current enumerable if still elements to check
            stack.push(StackFrame.new(current, index + 1))
          end
          if obj.is_a?(Hash) || obj.is_a?(Array)
            #If obj is enumerable add to stack
            stack.push(StackFrame.new(obj, 0))
          end
        end
        safe
      end




      def index_table_exists?
        !index_table.nil? && index_table.exists?
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
        new_table = nil
        idx_table = nil
        if index_table? && !dynamo_db.tables[index_table_name].exists?
          dynamo_db.tables.create(
                          table_name+"_INDEX", read_units, 
                          write_units, opts)  
          new_table     = dynamo_db.tables.create(
                          table_name, read_units, write_units, {
                            hash_key: {
                              hash_key_info.field.to_s+"_"+range_info.field.to_s => :string
                            },
                            range_key: {"dynameek_index" => :number}
                          })
        else
          new_table = dynamo_db.tables.create(table_name, read_units, write_units, opts)
        end
        while new_table.status == :creating || (!idx_table.nil? && idx_table.status == :creating)
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
      def index_table
        build!
        @index_table ||= dynamo_db.tables[index_table_name]
        if @index_table.exists? && !@index_table.schema_loaded?
          @index_table.load_schema
        end
        @index_table
      end
    end
  end
end
