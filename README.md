# Dynameek
A very lightweight ORMish model thing for amazon's dynamo db, after initialising the aws-sdk with something like:
    
    amazon_config_path = File.join(File.dirname(__FILE__), *%w[.. config amazon.config.yml])
    amazon_config = YAML.load(File.read(amazon_config_path))
    AWS.config(amazon_config[ENVIRONMENT])

##Models
   
You can create table models with this kind of syntax:

    class Conversion < Dynameek::Model

      field :client_id, :integer
      field :channel_id, :string
      field :goal_name, :string
      field :time, :datetime

      multi_column_hash_key [:client_id, :channel_id]
      range :time

    end

Creation of the models is as you'd expect
    
    con = Conversion.create(:client_id => 1, :channel_id => "google", :goal_name=> "Some Goal", :time => DateTime.now)

The models can be edited like normal (_no update\_attributes yet though_)

    con.goal_name="hello"
    con.save
    
These models can be queried by find and query, although this is still undergoing some refactoring at the moment it currently looks something like this:
    
    Conversion.find([1, "google"], DateTime.new([Some existing datetime]))
    
    Conversion.query(["1", "google"]).where(DateTime.now, :lt).where(DateTime.now - 10, :gte).all
  
  NB. The where clauses are only for referencing the range part of the composite hash key, there is currently no way to search by
  hash contents as that felt like it was against the point of a document store. 
  
### Disclaimery Bit

Delete is not currently supported because I don't need it. The gem is dynameek (unsurprisingly) but I wouldn't use it yet, far better
to clone down the project and modify it for your own use.