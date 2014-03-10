require 'spec_helper'
require Sinatra::Application.root + '/../lib/chawk_server'

describe Chawk::ChawkServer do

	def app
		Chawk::ChawkServer
	end


	describe "home page", :type => :feature do
	  it "home page" do
	    get '/'
	    expect(last_response).to be_ok
	    expect(last_response.body).to eq('Hello world!')
   	  end
	end

end