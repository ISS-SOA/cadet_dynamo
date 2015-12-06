ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
Dir.glob('./{config,models,services,controllers}/init.rb').each do |file|
  require file
end

include Rack::Test::Methods

def app
  CadetDynamo
end
