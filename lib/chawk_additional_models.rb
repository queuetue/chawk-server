require 'chawk'
module Chawk
	module Models
		class GUser
			include DataMapper::Resource
			property :id, Serial, :key => true
			property :google_id, String, length:120
			property :google_email, String, length:120
			property :email, String, length:120
			property :handle, String, length:30
			property :name, String, length:40
			property :family_name, String, length:20
			property :image, Text
			property :secret, Text
			property :api_key, String, length:200
			property :reset_token, Integer
			property :access_token, Integer
			belongs_to :agent, :required=>false
			has n, :alerts
		end

		class Alert
			include DataMapper::Resource
			property :id, Serial, :key => true
			property :created_at, DateTime
			property :message, Text
			property :message_level, Integer
			property :icon, String, length:20
			property :seen, Boolean
			property :sender, Integer
		end

		class NodeAccessRequest
			include DataMapper::Resource
			property :id, Serial, :key => true
			property :created_at, DateTime
			belongs_to :node
			belongs_to :g_user
		end

	end
end