require 'chawk'
require './lib/chawk_additional_models'
require './app/app'
Chawk.setup ENV['DATABASE_URL']
agent = Chawk::Models::Agent.first || Chawk::Models::Agent.create(name:"Steve Austin")
addr = Chawk.addr(agent, "foo")
