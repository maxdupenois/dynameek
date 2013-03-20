module Dynameek
  module Model
    module Query
      #Similar to dynamoids approach but lighter (hopefully)
      class QueryChain
      
        def initialize(model)
          @model = model
          @hash_key = nil
          @range = {eq: nil,  gte: nil, gt: nil, lte: nil, lt: nil}
        end
      
        def query(hash_key)
          @hash_key = hash_key
          self
        end
      
        def where(value, op=:eq)
          raise Exception.new("Op #{op.to_s} not recognised") if(!@range.keys.include?(op))
          @range[op] = value
          self
        end
      
        def delete
          each(&:delete)
        end
      
        def all
          run
        end
      
        def each
          all.each do |item|
            yield(item)
          end
        end
      
        def each_with_index
          all.each_with_index do |item, index|
            yield(item, index)
          end
        end
      
        RANGE_QUERY_MAP =
        {
          eq: :range_value,
          gte: :range_gte,
          gt: :range_greater_than,
          lte: :range_lte,
          lt: :range_less_than,
          # begins_with: :range_begins_with
        }
      
        private
      
        def run
          hash_key = @hash_key
          hash_key = hash_key.join(@model.multi_column_join) if(hash_key.is_a?(Array))
        
          query_hash = {:hash_value => hash_key, :select => :all}
        
          range = @range.select{|key, val| !val.nil?}
          if range.size == 2
            #only makes sense if one is a gt and the other a lt
            multiple_gt = (range.keys & [:gte, :gt]).size == 2
            multiple_lt = (range.keys & [:lte, :lt]).size == 2
            raise Exception.new("Query cannot have multiple greater than operations") if multiple_gt
            raise Exception.new("Query cannot have multiple less than operations") if multiple_lt
            start_of_range = range[:gte] || range[:gt].succ
            end_of_range = range[:lte] || range[:lt]
            
            converted_start_of_range = @model.convert_to_dynamodb(@model.range_info.type, start_of_range)
            converted_end_of_range = @model.convert_to_dynamodb(@model.range_info.type, end_of_range)
            
            range[:range_value] = Range.new(converted_start_of_range, converted_end_of_range, (range[:lte].nil?))
            range.delete(:lt)
            range.delete(:lte)
            range.delete(:gt)
            range.delete(:gte)
          elsif range.size > 2
            raise Exception.new("Dynameek does not currently support more than two range querys")
          else
            range = range.reduce({}) {|memo, (key, val)| memo[RANGE_QUERY_MAP[key]] = @model.convert_to_dynamodb(@model.range_info.type, val); memo}
          end
          query_hash.merge!(range)
          @model.table.items.query(query_hash).map{|item| 
            @model.item_to_instance(item)
          }
        end
      end
    
      [:query, :where, :all, :each, :each_with_index, :delete].each do |method|
        define_method(method) do |*args|
          qc = QueryChain.new(self)
          args = [] if !args
          qc.send method, *args
        end
      end
    
    end
  end
end