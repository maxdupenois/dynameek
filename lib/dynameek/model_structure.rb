module Dynameek
  module ModelStructure
    
    @@fields = {}
    @@hash_key = OpenStruct.new
    @@hash_key.field = nil
    @@hash_key.type = nil

    @@range = OpenStruct.new
    @@range.field = nil
    @@range.type = nil

    @@read_write = [10, 5]

    @@multi_column_hash_key_fields = []
    @@multi_column_join = "|"
    
    
    def field fieldname, type
      fieldname = fieldname.to_sym
      type = type.to_sym
      @@fields[fieldname] = type
      define_method(fieldname.to_s) { read_attribute(fieldname) }
      define_method("#{fieldname.to_s}?") { !read_attribute(fieldname).nil? }
      define_method("#{fieldname.to_s}=") {|value| write_attribute(fieldname, value) }
    end 



    def hash_key fieldname
      fieldname = fieldname.to_sym
      check_field(fieldname)
      @@hash_key.field = fieldname
      @@hash_key.type = @@fields[fieldname]
      define_method(:hash_key) { read_attribute(fieldname) }
    end

    def multi_column_join
      @@multi_column_join
    end
    def multi_column_join=(join)
      @@multi_column_join = join
    end
    def multi_column_hash_key?
      !@@multi_column_hash_key_fields.empty?
    end
    
    
    
    def multi_column_hash_key fieldnames
      fields = fieldnames.map(&:to_sym)
      fields.each{|f| check_field(f)}
      @@multi_column_hash_key_fields = fields
      fieldname = fieldnames.map(&:to_s).join("_").to_s
      @@fields[fieldname] = :string
      define_method(:hash_key) do
        @@multi_column_hash_key_fields.reduce([]) do |memo, field|
          memo << attributes[field]
          memo
        end.join(@@multi_column_join)
      end
      alias_method fieldname, :hash_key
      @@hash_key.field = fieldname
      @@hash_key.type = :string
    end
    
    def hash_key_field
      @@hash_key
    end


    def range fieldname
      fieldname = fieldname.to_sym
      check_field(fieldname)
      @@range.field = fieldname
      @@range.type = @@fields[fieldname]
    end

    
    def read_write read, write
      @@read_write = [read, write]
    end
    
    def read_units
      @@read_write[0]
    end
    def write_units
      @@read_write[1]
    end
    
    def fields
      @@fields
    end
    
    def range_field
      @@range.field.nil? ? nil : @@range
    end

    def check_field(fieldname)
      raise Exception("#{fieldname} is not a recognised field") if @@fields[fieldname].nil?
    end

  end
end

  