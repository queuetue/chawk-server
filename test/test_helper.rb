require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

require 'chawk'

require 'rack/test'
require 'minitest/autorun'
require 'minitest/pride'

ENV['RACK_ENV'] = 'test'

require_relative '../app/app'

include Rack::Test::Methods

def app
	Chawk::ChawkServer
end
