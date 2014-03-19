require 'sinatra'
require 'oauth2'
require 'json'
require 'chawk'
require './lib/chawk_additional_models'
require './app/point_routes'
require './app/user_routes'
require './app/addr_routes'

SITE_TITLE = "Chawk Server"
SESSION_SECRET= ENV['SESSION_SECRET']
G_API_CLIENT= ENV['G_API_CLIENT']
G_API_SECRET= ENV['G_API_SECRET']
G_API_SCOPES = [
			'https://www.googleapis.com/auth/userinfo.email',
			'https://www.googleapis.com/auth/userinfo.profile'].join(' ')

module Chawk
	SERVER_VERSION="0.0.43"
	module ServerConnections
		@@connections   = []
		@@notifications = []
		def self.connections
			return @@connections
		end
		def self.notifications
			return @@notifications
		end
	end

	class ChawkServer < Sinatra::Base
		enable :sessions
		enable :logging
		file = File.new("out.log", 'a+')
		file.sync = true

		use Rack::CommonLogger, file
	    use Rack::MethodOverride

	    register Sinatra::PointRoutes
	    register Sinatra::UserRoutes
	    register Sinatra::AddrRoutes

	    # for testing, we'll pull this out later
	    set :protection, :except => [:http_origin]

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

		before do
			pass if request.path_info == '/auth/g_callback'
			pass if request.path_info == '/signout'
			pass if request.path_info == '/signin'
			pass if request.path_info == "/points/:id/data"

		end

		get '/' do
			protected!
			erb :index
		end

		get '/data_change', provides: 'text/event-stream' do
			stream :keep_open do |out|
				Chawk::ServerConnections.connections << out
				out.callback {
					Chawk::ServerConnections.connections.delete(out)
				}
			end
		end

		get '/signin' do
			@g_sign_in_url = client.auth_code.authorize_url(:redirect_uri => g_redirect_uri,:scope => G_API_SCOPES)
			erb :sign_in, layout:false
		end

		get '/signout' do
			session[:g_access_token] = nil
			session[:user_id] = nil
			@messages << "You have logged out."
			redirect '/'
		end

		post "/node_access_request" do
			protected!
			node=Chawk::Models::Node.first(id=params[:node_id])
			user=Chawk::Models::GUser.first(id=params[:user_id])
			Chawk::Models::NodeAccessRequest.create(node:node,user:user)
		end

		get '/auth/g_callback' do
			new_token = client.auth_code.get_token(params[:code], :redirect_uri => g_redirect_uri)
			session[:g_access_token]  = new_token.token
			redirect '/'
		end

		def g_redirect_uri
			uri = URI.parse(request.url)
			uri.path = '/auth/g_callback'
			uri.query = nil
			uri.to_s
		end

		def access_token
			OAuth2::AccessToken.new(client, session[:g_access_token])
		end

		def timestamp
			Time.now.strftime("%H:%M:%S")
		end

		def has_addr?(agent,address)
			begin
				@addr = Chawk.addr(@user.agent,params[:id].to_s)
				return true
			rescue SecurityError
				return false
			end
		end

		def user=(new_user)
			@user = new_user
		end
		
		def user
			@user
		end

		def protected!
			redirect '/signin' unless authorized?
		end

		def authorized?
			if session[:g_access_token] && !session[:g_access_token].nil?
				# TODO: Deal with failures, outages, overall fragility here

				access_token = OAuth2::AccessToken.from_hash(client, {:access_token => session[:g_access_token]})

				session[:g_access_token]  = access_token.token
				begin
					info = access_token.get("https://www.googleapis.com/oauth2/v3/userinfo").parsed
				rescue OAuth2::Error
					return false
				end

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
			else
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
		helpers do

			def title
				@title
			end

			def site_title
				@site_title
			end

		end
	end
end
