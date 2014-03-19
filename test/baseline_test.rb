# test.rb
require File.expand_path '../test_helper.rb', __FILE__

class MyTest < MiniTest::Unit::TestCase

  	include Rack::Test::Methods

	describe "successful user" do

		def app
			Chawk::ChawkServer
		end

		before do
			@user = Chawk::Models::GUser.first(name:"Chuck Awesome")
			unless @user 
				@user = Chawk::Models::GUser.create(
						name:"Chuck Awesome", 
						email:"baconator@chuck.it", 
						agent:Chawk::Models::Agent.create(name:"chuck"),
						api_key:SecureRandom.uuid
						)
			end 			
		end

		def test_hello_world
			get '/'
			last_response.status.must_equal 200
			doc = Nokogiri::HTML(last_response.body)
			node = doc.css('title')[0]
			node.content.strip.must_equal "Chawk Server"
		end

		def test_get_points
			Chawk.addr(@user.agent,"foo").points << [1,2,3,4,5,6]
			get "/points/foo/"
			doc = Nokogiri::HTML(last_response.body)
			#puts "ZZZ - #{last_response.inspect} \n\n"
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