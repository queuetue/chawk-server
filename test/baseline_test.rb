# test.rb
require File.expand_path '../test_helper.rb', __FILE__

def getchuck
	# Go, chuck!  You can do it!
	user = Chawk::Models::GUser.first(name:"Chuck Awesome")
	unless user 
		user = Chawk::Models::GUser.create(
				name:"Chuck Awesome", 
				email:"baconator@chuck.it", 
				agent:Chawk::Models::Agent.create(name:"chuck"),
				api_key:SecureRandom.uuid
				)
	end 
	user			
end

class Chawk::ChawkServer
	def user
		@user
	end

	def authorized?
		@user = getchuck
		true
	end
end

class MyTest < MiniTest::Unit::TestCase

  	include Rack::Test::Methods

	describe "successful user" do

		def app
			Chawk::ChawkServer
		end

		before do
			@user = getchuck
		end

		def test_hello_world
			get '/'
			last_response.status.must_equal 200
			last_response.body.include?("Chawk Server").must_equal true
		end

		def test_get_points
			Chawk.addr(@user.agent,"foo").points << [1,2,3,4,5,6]
			get "/points/foo/"
			last_response.body.include?('var data = [{"x":1,"a":1,"id":1},{"x":2,"a":2,"id":2},{"x":3,"a":3,"id":3},{"x":4,"a":4,"id":4},{"x":5,"a":5,"id":5},{"x":6,"a":6,"id":6}]').must_equal true
		end
	end

	# get '/signin' do
	# get '/signout' do
	# get '/auth/g_callback' do
	# app.get "/points/:id/point/:point_id/?" do
	# app.get "/points/:id/data" do
	# app.get '/user' do
	# app.post "/addr/:id/relation" do
	# app.post "/addr/:id/public_read" do
	# post "/node_access_request" do
	# app.post "/points/:id/?" do
	# app.post "/points/:id/data" do
	# app.post "/api_key" do

	# get '/data_change', provides: 'text/event-stream' do


end