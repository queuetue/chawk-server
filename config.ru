#!/usr/bin/env rackup
# encoding: utf-8

require 'sprockets'

require File.expand_path("../config/boot.rb", __FILE__)

map '/img' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets/img'
  run environment
end

map '/js' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets/js'
  run environment
end

map '/css' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets/css'
  run environment
end

map '/font-awesome' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets/font-awesome'
  run environment
end

map '/fonts' do
  environment = Sprockets::Environment.new
  environment.append_path 'assets/fonts'
  run environment
end

run Chawk::ChawkServer
