require 'dynamoid'

Dynamoid.configure do |config|
  config.adapter = 'aws_sdk_v2'
  config.namespace = 'cadet_api'
  config.read_capacity = 10
  config.write_capacity = 10
end
