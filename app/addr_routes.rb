require "sinatra/base"

module Sinatra
	module AddrRoutes
		def self.registered(app)

			app.delete "/addr/:id/data" do
				protected!
				# TODO: Check for admin privs, consider paranoia mode, think about export / backup
				if has_addr?(@user.agent, params[:id].to_s)
					@addr.node.points.destroy
					@addr.node.values.destroy
					@addr.node.relations.destroy
					@addr.node.destroy
				end
				"OK"
			end

			app.post "/addr/:id/relation" do
				protected!
				if has_addr?(@user.agent, params[:id].to_s)
					user=Chawk::Models::GUser.first(id=params[:user_id])
					@addr.set_permissions(user.agent,read=params[:read],write=params[:write],admin=params[:admin])
				else
					erb :not_allowed, layout:@layout
				end				
			end

			app.post "/addr/:id/public_read" do
				protected!
				if has_addr?(@user.agent, params[:id].to_s)
					@addr.public_read = params[:value] == "true"
					''
				else
					erb :not_allowed, layout:@layout
				end				
			end
		end
	end
	register AddrRoutes
end
