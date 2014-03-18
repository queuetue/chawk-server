require "sinatra/base"

module Sinatra
		module PointRoutes
			def self.registered(app)

				app.get "/points/:id/point/:point_id/?" do
					protected!
					if has_addr?(@user.agent, params[:id].to_s)
						@point = @addr.node.points.get(params[:point_id])
						erb :point_index, layout:@layout
					else
						erb :not_allowed, layout:@layout
					end
				end

				app.get "/points/:id/?" do
					protected!
					if has_addr?(@user.agent, params[:id].to_s)
						@last = @addr.points.last
						step = 0
						@data = @addr.points.last(1000).collect{|d|{'x'=>step+=1,'a'=>d.value, 'id' =>d.id}}
						erb :points_index, layout:@layout
					else
						erb :not_allowed, layout:@layout
					end
				end

				app.post "/points/:id/?" do
					protected!
					if has_addr?(@user.agent, params[:id].to_s)
						data = params[:new_data].split(",").collect{|d|d.to_i}
						@addr.points.append(data,{:meta=>{
							recordingAgent:"ChawkServer manual (v#{Chawk::SERVER_VERSION})",
							source:request.host,
							remote:request.ip
							}})

						notification = ({
						'event' => 'DATACHANGE',
						'key' => params[:id],
						'timestamp' => Time.now()
						}).to_json

						Chawk::ServerConnections.notifications << notification
						Chawk::ServerConnections.notifications.shift if Chawk::ServerConnections.notifications.length > 10
						Chawk::ServerConnections.connections.each { |out| out << "data: #{notification}\n\n"}

						redirect "/points/" + params[:id]
					else
						erb :not_allowed, layout:@layout
					end
				end

				app.get "/points/:id/data" do
					protected_by_api!
					addr = Chawk.addr(@api_user.agent,params[:id].to_s)
					data = addr.points.last(1000)
					out = {}

					step = 0

					out['data'] = data.collect{|d|{'x'=>step+=1,'a'=>d.value, 'id' =>d.id}}
					out.to_json
				end

				app.post "/points/:id/data" do
					protected_by_api!
					addr = Chawk.addr(@api_user.agent,params[:id].to_s)
					#raise "#{params}"
					payload = JSON.parse params[:payload]

					payload["items"].each do |item|
						addr.points.append(item["v"].to_i, {:meta=>{
							recordingAgent:"ChawkServer API (v#{Chawk::SERVER_VERSION})",
							source:request.host,
							remote:request.ip
							}})
					end

					notification = ({
					'event' => 'DATACHANGE',
					'key' => params[:id],
					'timestamp' => Time.now()
					}).to_json

					Chawk::ServerConnections.notifications << notification
					Chawk::ServerConnections.notifications.shift if Chawk::ServerConnections.notifications.length > 10
					Chawk::ServerConnections.connections.each { |out| out << "data: #{notification}\n\n"}
					"OK"
				end
			end
		end
		register PointRoutes
end
