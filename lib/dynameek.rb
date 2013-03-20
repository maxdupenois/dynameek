module Dynameek
end

require File.join(File.dirname(__FILE__), *%w[dynameek model dynamo_db])
require File.join(File.dirname(__FILE__), *%w[dynameek model query])
require File.join(File.dirname(__FILE__), *%w[dynameek model structure])
require File.join(File.dirname(__FILE__), *%w[dynameek model])