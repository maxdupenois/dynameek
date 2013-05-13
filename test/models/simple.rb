class Simple 
  include Dynameek::Model


  field :my_id, :integer
  field :some_value, :string
  field :boolean_value, :boolean 
  field :binary_value, :binary  

  hash_key :my_id
  
  

end
