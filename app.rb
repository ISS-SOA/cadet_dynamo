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
    set :session_secret, "fixed secret"
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

  show_api_v1_deprecation = lambda do
    status 400
    "CadetDynamo api/v1 is deprecated: please use " +
    "<a href=\"/api/v3/\">#{request.host}/api/v3/</a>"
  end

  show_api_v2_root = lambda do
    "CadetDynamo /api/v2 is up and working, but is deprecated. " +
    "It is no longer tested. Please use: " +
    "<a href=\"/api/v3/\">#{request.host}/api/v3/</a>"
  end

  show_api_v3_root = lambda do
    "CadetDynamo API v3 is up and running at " +
    "<a href=\"/api/v3/\">#{request.host}/api/v3/</a>"
  end
  
  show_root = lambda do
    show_api_v3_root.call
  end

  get_cadet_info = lambda do
    content_type :json
    badges = get_user_badges
    badges.nil? ? halt(404) : badges.to_json
  end

  delete_cadet = lambda do
    begin
      Tutorial.destroy(params[:id])
    rescue
      halt 404
    end
  end

  get_tutorial_index = lambda do
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

  create_tutorial_query = lambda do
    begin
      req = JSON.parse(request.body.read)
    rescue
      halt 400
    end

    tutorial = new_tutorial(req)
    if tutorial.save
      redirect "/api/#{@ver}/tutorials/#{tutorial.id}"
    end
  end

  get_tutorial_v2 = lambda do
    content_type :json
    get_update_tutorial_json(params[:id]).missing
  end

  get_tutorial_v3 = lambda do
    content_type :json
    tut = get_update_tutorial_json(params[:id])
    { description: tut.description,
      usernames:   JSON[tut.usernames],
      badges:      JSON[tut.badges],
      completed:   JSON[tut.completed],
      missing:     JSON[tut.missing] }.to_json
  end

  capture_api_ver = lambda do |ver|
    @ver = ver
    pass
  end

  # API handlers
  get '/', &show_root

  get %r{/api/(v\d)/*}, &capture_api_ver
  put %r{/api/(v\d)/*}, &capture_api_ver
  post %r{/api/(v\d)/*}, &capture_api_ver
  delete %r{/api/(v\d)/*}, &capture_api_ver

  get '/api/v1/?*', &show_api_v1_deprecation

  get '/api/v2/?', &show_api_v2_root
  get '/api/v2/cadet/:username.json', &get_cadet_info
  get '/api/v2/tutorials/?', &get_tutorial_index
  post '/api/v2/tutorials', &create_tutorial_query
  delete '/api/v2/tutorials/:id', &delete_cadet
  get '/api/v2/tutorials/:id', &get_tutorial_v2

  get '/api/v3/?', &show_api_v3_root
  get '/api/v3/cadet/:username.json', &get_cadet_info
  get '/api/v3/tutorials/?', &get_tutorial_index
  post '/api/v3/tutorials', &create_tutorial_query
  delete '/api/v3/tutorials/:id', &delete_cadet
  get '/api/v3/tutorials/:id', &get_tutorial_v3
end
