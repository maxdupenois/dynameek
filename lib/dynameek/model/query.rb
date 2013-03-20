module Dynameek
  module Model
    module Query
      #Similar to dynamoids approach but lighter (hopefully)
    
      class QueryChain
      
        def initialize(model)
          @model = model
          @hash_key = nil
          @range = {eq: nil, within: nil, gte: nil, gt: nil, lte: nil, lt: nil, begins_with: nil}
        end
      
        def query(hash_key)
          @hash_key = hash_key
          self
        end
      
        def where(value, op=:eq)
          raise Exception("Op #{op.to_s} not recognised") if(!@range.keys.include?(op))
          @range[op] = value
          self
        end
      
        def all
          run
        end
      
        def each
          all.each
        end
      
        def each_with_index
          all.each_with_index
        end
      
        RANGE_QUERY_MAP =
        {
          eq: :range_value,
          within: :range_value,
          gte: :range_gte,
          gt: :range_greater_than,
          lte: :range_lte,
          lt: :range_less_than,
          begins_with: :range_begins_with
        }
      
        private
      
        def run
          hash_key = @hash_key
          hash_key = hash_key.join(@model.multi_column_join) if(hash_key.is_a?(Array))
        
          query_hash = {:hash_value => hash_key}
        
          query_hash = @range.reduce(query_hash) do |hsh, (key, val)|
            if(!val.nil?)
              hsh[RANGE_QUERY_MAP[key]] = @model.convert_to_dynamodb(@model.range_field.type, val)
            end
            hsh
          end
          @model.table.items.query(query_hash).map{|item| @model.item_to_instance(item)}
        
        end
      
    
      end
    
      [:query, :where, :all, :each, :each_with_index].each do |method|
        define_method(method) do |*args|
          qc = QueryChain.new(self)
          args = [] if !args
          qc.send method, *args
        end
      end
    
    end
  end
end