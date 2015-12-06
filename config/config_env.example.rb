# Skeleton file for true config_env.rb
# - put your keys/secrets in '...'

config_env do
  set 'AWS_ACCESS_KEY_ID', '...'
  set 'AWS_SECRET_ACCESS_KEY', '...'
end

config_env :production do
  # AWS Region: US East (N. Virginia)
  set 'AWS_REGION', 'us-east-1'

  # Memcachier region: US
  set 'MEMCACHIER_SERVERS', '...'
  set 'MEMCACHIER_USERNAME', '...'
  set 'MEMCACHIER_PASSWORD', '...'
end

config_env :development, :test do
  # AWS Region: EU Central (Frankfurt)
  set 'AWS_REGION', 'eu-central-1'

  # Memcachier region: EU
  set 'MEMCACHIER_SERVERS', '...'
  set 'MEMCACHIER_USERNAME', '...'
  set 'MEMCACHIER_PASSWORD', '...'
end
