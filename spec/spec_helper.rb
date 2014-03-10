#require 'bundler'
#require "simplecov"
#SimpleCov.start

ENV['RACK_ENV']= "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")


RSpec.configure do |conf|
  conf.include Rack::Test::Methods#, :type=>:features

  #Capybara.register_driver :rack_test do |app|
  #  Capybara::RackTest::Driver.new(app, :headers => { 'HTTP_USER_AGENT' => 'Capybara' })
  #end

#  conf.include Capybara::DSL, :type => :request

  #conf.include Capybara::DSL
  #Capybara.server_port = 9292
  #Capybara.register_driver :poltergeist do |app|
  #  Capybara::Poltergeist::Driver.new(
  #    app,
  #    window_size: [1280, 1024] ,
  #    debug:       true
  #  )
  #end
  #Capybara.default_driver    = :poltergeist
  #Capybara.javascript_driver = :poltergeist

end