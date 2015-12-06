ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
Dir.glob('./{config,model,controller}/init.rb').each { |file| require file}

include Rack::Test::Methods

def app
  CadetDynamo
end
