class WithIndexTable
  include Dynameek::Model

  field :client_id, :integer
  field :channel_id, :string
  field :advert_id, :integer
  field :time, :datetime

  multi_column_hash_key [:client_id, :channel_id]
  range :time

  use_index_table
end
