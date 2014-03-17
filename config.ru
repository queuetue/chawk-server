#!/usr/bin/env rackup
# encoding: utf-8

require File.expand_path("../config/boot.rb", __FILE__)

map '/assets' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets/js'
  environment.append_path 'assets/css'
  environment.append_path 'assets/font-awesome'
  environment.append_path 'assets/fonts'
  run environment
end

#run Rack::URLMap.new({
#  "/"    => Chawk::ChawkServer
#})

map "/" do
	run Chawk::ChawkServer
end