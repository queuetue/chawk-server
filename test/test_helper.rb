require 'chawk'

require 'rack/test'
require 'minitest/autorun'
require 'minitest/pride'

ENV['RACK_ENV'] = 'test'

require 'chawk'
require './lib/chawk_additional_models'
require './app/app'

Chawk.setup 'sqlite::memory:'  #ENV['DATABASE_URL']

DataMapper.auto_migrate!

Chawk::Models::GUser.create(name:"Charley Testington")

include Rack::Test::Methods
