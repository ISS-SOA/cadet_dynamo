source 'http://rubygems.org'
ruby '2.2.3'

# gems for internal operations
gem 'thin'
gem 'sinatra'
gem 'sinatra-contrib'
gem 'codebadges'
gem 'json'

gem 'activesupport'
gem 'concurrent-ruby-ext'

# gems requiring credentials for 3rd party services
gem 'config_env'
gem 'aws-sdk', '~> 2'     # DynamoDB (Dynamoid), SQS Message Queue
gem 'dynamoid', '~> 1'
gem 'dalli'               # Memcachier

group :test do
  gem 'minitest'
  gem 'rack'
  gem 'rack-test'
  gem 'rake'
end

group :development do
  gem 'tux'
end
