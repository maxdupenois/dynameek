class Conversion 
  include Dynameek::Model

  field :client_id, :integer
  field :channel_id, :string
  field :goal_name, :string
  field :time, :datetime
  
  multi_column_hash_key [:client_id, :channel_id]
  range :time
  

end