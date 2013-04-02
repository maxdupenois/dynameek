require 'rspec'
require 'aws-sdk'

require File.join(File.dirname(__FILE__), *%w[.. .. lib dynameek])

AWS.config(:use_ssl => false,
           :dynamo_db_endpoint => 'localhost',
           :dynamo_db_port => 4567,
           :access_key_id => "xxx",
           :secret_access_key => "xxx")

require File.join(File.dirname(__FILE__), *%w[.. models conversion])
require File.join(File.dirname(__FILE__), *%w[.. models with_index_table])
require File.join(File.dirname(__FILE__), *%w[.. models simple])
