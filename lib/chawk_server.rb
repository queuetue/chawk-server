require "./config/database.rb"

module Chawk
	class ChawkServer < Sinatra::Base

		board = Chawk::Board.new()

		get '/' do
			erb :index, :layout => :base
		end

		before %r{/points.*} do
		  content_type :json
		end

		post %r"^/points/(\w+/)+(/*)$" do
		url_regex = %r"(\w+)"
			m = request.path_info.scan(url_regex)
			(root,*path) = m.flatten
			addr = board.points.addr(path)
			addr << params[:value].to_i
			redirect to("/points/#{addr.address}/last" )
		end

		get %r"^/points/(\w+/)+last(/*)$" do
			url_regex = %r"(\w+)"
			m = request.path_info.scan(url_regex)
			(root,*path,cmd) = m.flatten 
			#raise "#{path}"
			addr = board.points.addr(path)
			if addr
				if params[:count].nil? || params[:count]==1
					data = addr.last
					if data.nil?
						payload_data = []
					else
						payload_data = [ { x: addr.last.timestamp, y: addr.last.value }]
					end
				else
					data = addr.last(params[:count].to_i)
					if data.nil? || data.empty?
						payload_data = []
					else
						payload_data = data.inject([]){|result,d|result << {x:d.timestamp,y:d.value}}
					end
				end

				payload = {
					address:addr.address,
					node_id:addr.node.id,
					data: payload_data
				}
				payload.to_json
			else
				"There was a problem loading #{path}"
			end
		end

		get %r"^/points/(\w+/)+since(/*)$" do
			url_regex = %r"(\w+)"
			m = request.path_info.scan(url_regex)
			(root,*path,cmd) = m.flatten 
			addr = board.get_addr(path)

			data = addr.since(Time.now-params[:ago].to_i)
			if data.nil? || data.empty?
				payload_data = []
			else
				payload_data = data.inject([]){|result,d|result << {x:d.timestamp,y:d.value}}
			end

			payload = {
				addr:addr.version,
				address:addr.address,
				node_id:10,
				data: payload_data
			}
			payload.to_json
		end

	end
end


#^\/points\/(\w+\/)+current$


# list all
#get '/points' do
#  Widget.all.to_json
#end

# view one
#get '/points/:id' do
#  widget = Widget.find(params[:id])
#  return status 404 if widget.nil?
#  widget.to_json
#end

# create
#post '/points' do
#  widget = Widget.new(params['widget'])
#  widget.save
#  status 201
#end

# update
#put '/points/:id' do
#  widget = Widget.find(params[:id])
#  return status 404 if widget.nil?
#  widget.update(params[:widget])
#  widget.save
#  status 202
#end

#delete '/points/:id' do
#  widget = Widget.find(params[:id])
#  return status 404 if widget.nil?
#  widget.delete
#  status 202
#end
