# test.rb
require File.expand_path '../test_helper.rb', __FILE__

class MyTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods

  def app
    Chawk::ChawkServer
  end

  def test_hello_world
    get '/'
    last_response.status.must_equal 302
    last_response.header["Location"].must_equal "http://example.org/signin"
  end
end