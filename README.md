# Dynameek
A very lightweight ORMish model thing for amazon's dynamo db, after initialising the aws-sdk with something like:
    
    amazon_config_path = File.join(File.dirname(__FILE__), *%w[.. config amazon.config.yml])
    amazon_config = YAML.load(File.read(amazon_config_path))
    AWS.config(amazon_config[ENVIRONMENT])
    
You can create table models with this kind of syntax:

    class Conversion < DynamodbModel

      field :client_id, :integer
      field :channel_id, :string
      field :goal_name, :string
      field :time, :datetime

      multi_column_hash_key [:client_id, :channel_id]
      range :time


    end

These models can be queried by find and range_query, although this is still undergoing some refactoring at the moment
so i'm not going to show how you do that yet (it's kinda ugly). Feel free to look in the code, I'd imagine it's going to change
a lot. I short don't use this unless you're me, use dynamoid or the sdk by itself.