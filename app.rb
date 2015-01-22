require 'config_env'
require 'dalli'
require 'aws-sdk'
require 'sinatra/base'
require 'codebadges'
require_relative 'cadet_helpers'
require_relative 'model/tutorial'

##
# Fork of CadetService, using DynamoDB instead of Postgres
# - requires config:
#   - create ENV vars AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION
class CadetDynamo < Sinatra::Base
  helpers CadetHelpers

  configure :development do
    # ignore if not using shotgun in development
    set :session_secret, "f7ds942kjsd7k23j"
  end

  configure :development, :test do
    ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
  end

  configure do
    set :cadet_cache, Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || "").split(","),
      {:username => ENV["MEMCACHIER_USERNAME"],
        :password => ENV["MEMCACHIER_PASSWORD"],
        :socket_timeout => 1.5,
        :socket_failure_delay => 0.2
        })
    set :cadet_cache_ttl, 86_400    # 24hrs

    set :cadet_queue, AWS::SQS.new(region: ENV['AWS_REGION'])
    set :cadet_queue_name, 'RecentCadet'
  end

  configure :production, :development do
    enable :logging
  end


  before do
    @HOST_WITH_PORT = request.host_with_port
  end

  get '/' do
    "CadetDynamo api/v2 is up and working at /api/v2/"
  end

  # API handlers
  get '/api/v1/?*' do
    status 400
    "CadetDynamo api/v1 is deprecated: please use " +
    "<a href=\"/api/v2/\">#{request.host}/api/v2/</a>"
  end

  get '/api/v2/?' do
    "CadetDynamo /api/v2 is up and working"
  end

  get '/api/v2/cadet/:username.json' do
    content_type :json
    badges = get_user_badges
    badges.nil? ? halt(404) : badges.to_json
  end

  delete '/api/v2/tutorials/:id' do
    begin
      Tutorial.destroy(params[:id])
    rescue
      halt 404
    end
  end

  post '/api/v2/tutorials' do
    begin
      req = JSON.parse(request.body.read)
    rescue
      halt 400
    end

    tutorial = new_tutorial(req)
    if tutorial.save
      redirect "/api/v2/tutorials/#{tutorial.id}"
    end
  end

  get '/api/v2/tutorials/:id' do
    content_type :json
    begin
      tutorial = Tutorial.find(params[:id])
    rescue
      halt 404
    end

    begin
      usernames = JSON.parse(tutorial.usernames)
      badges = JSON.parse(tutorial.badges)

      results = check_badges(usernames, badges)
      tutorial.missing = results[:missing].to_json
      tutorial.completed = results[:completed].to_json
      tutorial.save
    rescue
      halt 400
    end

    tutorial.missing
  end

  get '/api/v2/tutorials/?' do
    content_type :json
    body = request.body.read

    begin
      index = Tutorial.all.map do |t|
        { id: t.id, description: t.description,
          created_at: t.created_at, updated_at: t.updated_at }
      end
    rescue
      halt 400
    end

    index.to_json
  end
end
