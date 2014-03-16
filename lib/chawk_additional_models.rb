require 'chawk'
module Chawk
	module Models
		class GUser
			include DataMapper::Resource
			property :id, Serial, :key => true
			property :email, String, length:120
			property :handle, String, length:30
			property :name, String, length:40
			property :family_name, String, length:20
			property :image, Text
			property :secret, Text
			property :agent_id, Integer
			belongs_to :agent#, :child_key => [:foreign_id]
		end
	end
end