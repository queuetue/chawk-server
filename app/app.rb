require 'sinatra'
require 'oauth2'
require 'json'
require 'chawk'
require './lib/chawk_additional_models'

SITE_TITLE = "Chawk Server"
SESSION_SECRET= ENV['SESSION_SECRET']
G_API_CLIENT= ENV['G_API_CLIENT']
G_API_SECRET= ENV['G_API_SECRET']
G_API_SCOPES = [
			'https://www.googleapis.com/auth/plus.me',
			'https://www.googleapis.com/auth/userinfo.email',
			'https://www.googleapis.com/auth/userinfo.profile'].join(' ')

module Chawk

	class ChawkServer < Sinatra::Base
		enable :sessions
		enable :logging

	    use Rack::MethodOverride

		set :session_secret, SESSION_SECRET 
	
		connections = []
		notifications = []

		def client
			client ||= OAuth2::Client.new(G_API_CLIENT, G_API_SECRET, {
				:site => 'https://accounts.google.com',
				:authorize_url => "/o/oauth2/auth",
				:token_url => "/o/oauth2/token"
			})
		end

		before do
			@messages = []
			@title = ""
			@site_title = SITE_TITLE
		end

		def title
			@title
		end

		def site_title
			@site_title
		end

		def timestamp
			Time.now.strftime("%H:%M:%S")
		end

		before do
			@layout = :not_logged_in_layout

			pass if request.path_info == '/auth/g_callback'
			pass if request.path_info == '/signout'

			if session[:access_token]
				# TODO: Deal with failures, outages, overall fragility here

				access_token = OAuth2::AccessToken.from_hash(client, { 
					:access_token => session[:access_token], 
					:refresh_token =>  session[:refresh_token], 
					:header_format => 'OAuth %s' } ).refresh!

				session[:access_token]  = access_token.token
				session[:refresh_token] = access_token.refresh_token

				access_token.refresh!
				info = access_token.get("https://www.googleapis.com/oauth2/v3/userinfo").parsed

				@user = Chawk::Models::GUser.first(:google_id=>info["sub"]) 
				if @user
					@user.google_email = info["email"]
					@user.name = info["name"]
					@user.family_name = info["family_name"]
					@user.image = info["picture"]
					@user.save
				else
					Chawk::Models::GUser.create(google_id:info["sub"], 
							agent:Chawk::Models::Agent.create(name:info["sub"]),
							google_email:info["email"],							
							email:info["email"],
							handle:info["email"],
							name:info["name"],
							family_name:info["family_name"],
							image:info["picture"] )
				end

				@layout = :layout

			end
		end

		get '/' do
			if !session[:access_token].nil?
				erb :index, layout:@layout
			else
				@g_sign_in_url = client.auth_code.authorize_url(:redirect_uri => g_redirect_uri,:scope => G_API_SCOPES,:access_type => "offline")
				erb :sign_in, layout:@layout
			end
		end

		get '/connect', provides: 'text/event-stream' do
			stream :keep_open do |out|
				connections << out
				out.callback {
					connections.delete(out)
				}
			end
		end

		get '/signout' do
			session[:access_token] = nil
			session[:refresh_token] = nil
			@messages << "You have logged out."
			redirect '/'
		end

		get '/user' do
			@title = "Profile"
			erb :user_edit, layout:@layout
		end

		put '/user' do
			@user.email = (params[:email])
			@user.handle = (params[:handle])
			@user.save
			@user.alerts.create(message:"Your information has been saved",message_level:5,seen:false)
			redirect '/'
		end


		get '/auth/g_callback' do
			new_token = client.auth_code.get_token(params[:code], :redirect_uri => g_redirect_uri)
			session[:access_token]  = new_token.token
			session[:refresh_token] = new_token.refresh_token
			redirect '/'
		end

		get "/points/:id/data" do
			if @user && @user.agent
				addr = Chawk.addr(@user.agent,params[:id].to_s)
				data = addr.points.last(1000)
				out = {}

				step = 0

				out['data'] = data.collect{|d|{'x'=>step+=1,'a'=>d.value}}
				out.to_json
			end
		end

		get "/points/:id/" do
			erb :points_index, layout:@layout
		end

		post "/points/:id/data" do
			if @user && @user.agent
				addr = Chawk.addr(@user.agent,params[:id].to_s)
				payload = JSON.parse params[:payload]
				#raise "#{payload}"

				payload["items"].each do |item|
					addr.points << item["v"].to_i
				end

			    notification = ({
			    		'event' => 'DATACHANGE',
			    		'key' => params[:id],
			    		'timestamp' => timestamp
			    		}).to_json

			    notifications << notification

				notifications.shift if notifications.length > 10
    			connections.each { |out| out << "data: #{notification}\n\n"}

    			"PAYLOAD: #{payload}"
    		else
    			raise "HUH?"
			end
		end

		def g_redirect_uri
			uri = URI.parse(request.url)
			uri.path = '/auth/g_callback'
			uri.query = nil
			uri.to_s
		end

		def access_token
			OAuth2::AccessToken.new(client, session[:access_token], :refresh_token => session[:refresh_token])
		end


	end
end