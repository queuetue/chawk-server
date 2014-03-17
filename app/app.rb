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
		file = File.new("out.log", 'a+')
		file.sync = true
		use Rack::CommonLogger, file

		connections   = []
		notifications = []

	    use Rack::MethodOverride

		set :session_secret, SESSION_SECRET 
	
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

			if session[:access_token] && !session[:access_token].nil?
				# TODO: Deal with failures, outages, overall fragility here

				#  logger.info "ACCESS TOKEN: #{session[:access_token]} // #{session[:refresh_token]}"

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
					@user = Chawk::Models::GUser.create(google_id:info["sub"], 
							agent:Chawk::Models::Agent.create(name:info["sub"]),
							google_email:info["email"],							
							email:info["email"],
							handle:info["email"],
							name:info["name"],
							family_name:info["family_name"],
							image:info["picture"],
							api_key:SecureRandom.uuid )
				end
				response.set_cookie("chawk.api_key", value:@user.api_key, path:"/"	)
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

		get '/data_change', provides: 'text/event-stream' do
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
			session[:user_id] = nil
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
			@user.alerts.create(message:"Your information has been saved.",message_level:5,seen:false)
			redirect '/user'
		end

		post "/api_key" do
			@user.api_key = SecureRandom.uuid
			@user.save
			@user.alerts.create(message:"Your api key has been changed.",message_level:5,seen:false)
			redirect '/user'
		end

		post "/node_access_request" do
			node=Chawk::Models::Node.first(id=params[:node_id])
			user=Chawk::Models::GUser.first(id=params[:user_id])
			Chawk::Models::NodeAccessRequest.create(node:node,user:user)
		end

		post "/addr/:id/relation" do
			if has_addr?(@user.agent, params[:id].to_s)
				user=Chawk::Models::GUser.first(id=params[:user_id])
				@addr.set_permissions(user.agent,read=params[:read],write=params[:write],admin=params[:admin])
			else
				erb :not_allowed, layout:@layout
			end				
		end

		get '/auth/g_callback' do
			new_token = client.auth_code.get_token(params[:code], :redirect_uri => g_redirect_uri)
			session[:access_token]  = new_token.token
			session[:refresh_token] = new_token.refresh_token
			redirect '/'
		end

		get "/points/:id/?" do
			if has_addr?(@user.agent, params[:id].to_s)
				@last = @addr.points.last
				step = 0
				@data = @addr.points.last(1000).collect{|d|{'x'=>step+=1,'a'=>d.value}}
				erb :points_index, layout:@layout
			else
				erb :not_allowed, layout:@layout
			end
		end

		post "/points/:id/?" do
			if has_addr?(@user.agent, params[:id].to_s)
				data = params[:new_data].split(",").collect{|d|d.to_i}
				@addr.points << data

				notification = ({
				'event' => 'DATACHANGE',
				'key' => params[:id],
				'timestamp' => Time.now()
				}).to_json

				#raise "NOTIFY #{notification}"

				notifications << notification
				notifications.shift if notifications.length > 10
				connections.each { |out| out << "data: #{notification}\n\n"}

				redirect "/points/" + params[:id]
			else
				erb :not_allowed, layout:@layout
			end
		end

		get "/points/:id/data" do
			protected_by_api!
			addr = Chawk.addr(@api_user.agent,params[:id].to_s)
			data = addr.points.last(1000)
			out = {}

			step = 0

			out['data'] = data.collect{|d|{'x'=>step+=1,'a'=>d.value}}
			out.to_json
		end

		post "/points/:id/data" do
			protected_by_api!
			addr = Chawk.addr(@user.agent,params[:id].to_s)
			payload = JSON.parse params[:payload]

			payload["items"].each do |item|
				addr.points << item["v"].to_i
			end

			datachange_notify(params[:id])

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


		helpers do
			def has_addr?(agent,address)
				begin
					@addr = Chawk.addr(@user.agent,params[:id].to_s)
					return true
				rescue SecurityError
					return false
				end
			end


			def protected_by_api!
				return if authorized_by_api?
				#headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
				halt 403, "Not authorized\n"
			end

			def authorized_by_api?
				unless params[:api_key]
					return false
				end
				@api_user = Chawk::Models::GUser.first(api_key:params[:api_key])
				unless @api_user
					return false
				end
				true
			end

  		end

	end
end
