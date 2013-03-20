# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dynameek/version'

Gem::Specification.new do |gem|
  gem.name          = "dynameek"
  gem.version       = Dynameek::VERSION
  gem.authors       = ["Max Dupenois"]
  gem.email         = ["max.dupenois@forward.co.uk"]
  gem.description   = %q{A very lightweight model for DynamoDB tables in, certainly not in a finished state}
  gem.summary       = %q{Dynameek - A dynamodb model}
  gem.homepage      = "http://github.com/maxdupenois/dynameek"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency("aws-sdk")
  gem.add_development_dependency("rspec")
  gem.add_development_dependency("fake_dynamo")
end
