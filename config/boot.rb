ENV["RACK_ENV"] ||= "development"

require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.require(:default, ENV["RACK_ENV"].to_sym)

Dir["./lib/**/*.rb"].each { |f| require f }

db_uri = 'sqlite::memory:'
DataMapper::Logger.new('db.log', :debug)
DataMapper::Model.raise_on_save_failure = true
DataMapper.logger.debug "Here we go!"
adapter = DataMapper.setup(:default, db_uri)
DataMapper.finalize
DataMapper.auto_upgrade!
