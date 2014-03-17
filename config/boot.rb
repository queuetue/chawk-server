ENV["RACK_ENV"] ||= "development"

require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, ENV["RACK_ENV"].to_sym)

Dir["./lib/**/*.rb"].each { |f| require f }
Dir["./app/**/*.rb"].each { |f| require f }

DataMapper::Logger.new('db.log', :debug)
Chawk.setup(ENV['DATABASE_URL'])

