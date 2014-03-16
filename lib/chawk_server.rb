require 'sinatra'
require 'oauth2'
require 'json'
require 'chawk'
require './lib/chawk_additional_models'

SESSION_SECRET= ENV['SESSION_SECRET']
G_API_CLIENT= ENV['G_API_CLIENT']
G_API_SECRET= ENV['G_API_SECRET']
G_API_SCOPES = [	'https://www.googleapis.com/auth/plus.me',
			'https://www.googleapis.com/auth/userinfo.email',
			'https://www.googleapis.com/auth/userinfo.profile'].join(' ')


module Chawk
	class ChawkServer < Sinatra::Base
		enable :sessions
		enable :logging

		set :views_folder,  "#{settings.root}/../lib/views"
		set :public_folder, "#{settings.root}/../public"
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
		end

		before do
			pass if request.path_info == '/auth/g_callback'
			if !session[:access_token].nil?
				# TODO: Deal with failures, outages, overall fragility here
				info = access_token.get("https://www.googleapis.com/oauth2/v3/userinfo").parsed
				@user = Chawk::Models::GUser.first(:email=>info["email"]) || Chawk::Models::GUser.create(:email=>info["email"])
				@user.name = info["name"]
				@user.family_name = info["family_name"]
				@user.image = info["picture"]
				#@user.token = session[:access_token]
				@user.save

				unless @user.agent
					begin 
						agent = Chawk::Models::Agent.create(name:info["name"])
					rescue DataMapper::SaveFailureError => e
						puts "Error saving agent: #{e.to_s} "#validation: #{agent.errors.values.join(', ')}"
					end

					@user.agent = agent
					@user.save
				end

			end
		end

		get '/' do
			if !session[:access_token].nil?
				erb :index
			else
				@g_sign_in_url = client.auth_code.authorize_url(:redirect_uri => g_redirect_uri,:scope => G_API_SCOPES,:access_type => "offline")
				erb :sign_in
			end
		end

		get '/profile' do
			erb :profile
		end

		get '/auth/g_callback' do
			new_token = client.auth_code.get_token(params[:code], :redirect_uri => g_redirect_uri)
			session[:access_token]  = new_token.token
			redirect '/'
		end

		get "/points/:id/data" do
			if @user && @user.agent
				addr = Chawk.addr(@user.agent,params[:id].to_s)
				data = addr.points.last(10)
				"<table>" + data.collect{|d|"<tr><td>#{d.value}</td></tr>"}.join("")+"</table>"
			end
		end

		post "/points/:id/data" do
			if @user && @user.agent
				addr = Chawk.addr(@user.agent,params[:id].to_s)
				payload = params[:payload]
				raise "#{payload["items"]}"

				payload["items"].each do |item|
					addr.points << item["v"].to_i
				end
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

		# before do
		# 	pass if request.path_info == '/'
		# 	pass if request.path_info == '/oauth2callback'
		# 	pass if request.path_info == '/connect'

		# 	token        = session['access_token']
		# 	refresh      = session['refresh_token']
		# 	@instance_url = session['instance_url']

		# 	if token
		# 		@access_token = OAuth2::AccessToken.from_hash(client, { :access_token => token, :refresh_token =>  refresh}).refresh!
		# 	else
		# 		redirect oauth2_client.auth_code.authorize_url(:redirect_uri => "https://#{request.host}/connect")
		# 	end 
		# end

		#begin
		#	access_token = OAuth2::AccessToken.from_hash(client, :refresh_token => @refresh_token).refresh!
		#	response = access_token.get("https://www.googleapis.com/oauth2/v3/userinfo")
		#	erb :index, :layout => :base
		#rescue OAuth2::Error,
		#	@messages << "Your access token is not accepted."
		#	erb :login, :layout => :base
		#end

		#puts "REFRESH #{@foo} #{response.body}"

		#access_token_obj = auth_client_obj.auth_code.get_token(code, { :redirect_uri => redirect_uri, :token_method => :post })
		#@access_token = ForceToken.from_hash(oauth2_client, { :access_token => token, :refresh_token =>  refresh, :header_format => 'OAuth %s' } )


		# get '/connect' do
		# 	redirect client.auth_code.authorize_url(:redirect_uri => redirect_uri,:scope => G_API_SCOPES,:access_type => "offline")
		# end

		# session['access_token'] = access_token.token
		# session['refresh_token'] = access_token.refresh_token
		# session['instance_url'] = access_token.params['instance_url']

		# #logger.info "ACCESS TOKEN: #{access_token.to_hash}"

		# response = JSON.parse(access_token.get("https://www.googleapis.com/oauth2/v3/userinfo").body)
		# "ACCESS TOKEN: #{access_token.to_hash} Email: #{response[:email]}"

		# #access_token = "ya29.1.AADtN_UqKSZ9WAwGdNgGQpvexC45rnx9x-PX2Yeh1HT4FR70WBxT99CqHMjLiT1vnhi1Pg"


		# ##response = OAuth2::AccessToken.from_hash(client, :refresh_token => REFRESH_TOKEN).refresh!
		# ##puts response.token
		# ##puts response.expires_at



		# #user_response = Net::HTTP::get_response "https://www.googleapis.com/oauth2/v3/userinfo?access_token=" + access_token

		# #"Doing good: <br /><pre>#{access_token.to_hash}<br/>#{user_response.body}</pre>"

		# #this is where our API call is going to go
		# #response = access_token.get('https://www.googleapis.com/calendar/v3/calendars/{your-calendar-id}').parsed

		# access_token_obj = auth_client_obj.auth_code.get_token(code, { :redirect_uri => redirect_uri, :token_method => :post })
		# # STEP 4
		# puts "Token is: #{access_token_obj.token}"
		# puts "Refresh token is: #{access_token_obj.refresh_token}"
		# puts "api_client_obj = OAuth2::Client.new(client_id, client_secret, {:site => 'https://www.googleapis.com'})"
		# puts "api_access_token_obj = OAuth2::AccessToken.new(api_client_obj, '#{access_token_obj.token}')"
		# puts "api_access_token_obj.get('some_relative_path_here') OR in your browser: http://www.googleapis.com/some_relative_path_here?access_token=#{access_token_obj.token}"
		# puts "\n\n... and when that access_token expires in 1 hour, use this to refresh it:\n"
		# puts "refresh_client_obj = OAuth2::Client.new(client_id, client_secret, {:site => 'https://accounts.google.com', :authorize_url => '/o/oauth2/auth', :token_url => '/o/oauth2/token'})"
		# puts "refresh_access_token_obj = OAuth2::AccessToken.new(refresh_client_obj, '#{access_token_obj.token}', {refresh_token: '#{access_token_obj.refresh_token}'})"
		# puts "refresh_access_token_obj.refresh!"
