require "sinatra/base"

module Sinatra
	module UserRoutes
		def self.registered(app)

			app.get '/user' do
				protected!
				@title = "Profile"
				erb :user_edit, layout:@layout
			end

			app.put '/user' do
				protected!
				@user.email = (params[:email])
				@user.handle = (params[:handle])
				@user.save
				@user.alerts.create(message:"Your information has been saved.",message_level:5,seen:false)
				redirect '/user'
			end

			app.post "/api_key" do
				protected!
				@user.api_key = SecureRandom.uuid
				@user.save
				@user.alerts.create(message:"Your api key has been changed.",message_level:5,seen:false)
				redirect '/user'
			end
		end
	end
	register UserRoutes
end
