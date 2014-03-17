<img src="https://rawgithub.com/queuetue/chawk-gem/master/lib/chawk/Jackdaw.svg" alt="Drawing" width="400px"/>

ChawkServer
============

ChawkServer is a time series data storage engine written in Ruby.  It uses chawk-gem internally to manage data and Google for authentication via oauth2.

## Demo Server

There is usually a test server up at [chawk-server.herokuapp.com](http://chawk-server.herokuapp.com).  It goes down regularly and the data gets wiped on a frequent basis. 

## Setup  

This process is not automatic and requires some knowledge of Rack and DataMapper.

	go to https://console.developers.google.com/project
	Click "CREATE PROJECT", name it whatever, wait a bit.
	Click APIs and Auth / Credentials / "CREATE NEW CLIENT ID"
	Application type Web Application
		Authorized JS origin: your website
		Authorized redirect URI: http://your.website/auth/g_callback

	Client ID goes into ENV['G_API_CLIENT']
	Client Secret goes into ENV['G_API_SECRET']
	Setup a PG database and set ENV['DATABASE_URL']

	run DataMapper.auto_migrate!  !!!!! YOU ARE RESPONSIBLE FOR BACKUPS !!!!

	Set a unique ENV['SESSION_SECRET']

You should now be able to run ChawkServer.  This procedure, and these instructions will improve over time.

