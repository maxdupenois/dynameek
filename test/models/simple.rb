class Simple 
  include Dynameek::Model


  field :my_id, :integer
  field :some_value, :string
  

  hash_key :my_id
  
  

end