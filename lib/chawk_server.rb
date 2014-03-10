module Chawk
	class ChawkServer < Sinatra::Base

		set :sessions, true
		set :logging, true
		set :dump_errors, false

		get '/' do
			'Hello world!'
		end

		get %r"^/points/(\w+/)+last(/*)$" do
			url_regex = %r"(\w+)"
			m = request.path_info.scan(url_regex)
			(root,*path,cmd) = m.flatten 
			pointer = ArrayPointer.new(path)
			"ADDRESS: #{pointer.address}"
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
