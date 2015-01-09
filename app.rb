require 'sinatra/base'
require 'codebadges'
require 'json'
require 'dalli'
require_relative 'model/tutorial'

##
# Fork of CadetService, using DynamoDB instead of Postgres
# - requires config:
#   - create ENV vars AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION
class CadetDynamo < Sinatra::Base

  configure :production, :development do
    enable :logging
  end

  configure :development do
    set :session_secret, "something"    # ignore if not using shotgun in development
  end

  set :cache, Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || "").split(","),
                                  {:username => ENV["MEMCACHIER_USERNAME"],
                                    :password => ENV["MEMCACHIER_PASSWORD"],
                                    :socket_timeout => 1.5,
                                    :socket_failure_delay => 0.2
                                    })
  set :cache_username_ttl, 86_400    # 24hrs

  helpers do
    def get_badges(username)
      settings.cache.fetch(username, ttl=settings.cache_username_ttl) do
        CodeBadges::CodecademyBadges.get_badges(username)
      end
    end

    def user
      username = params[:username]
      return nil unless username

      badges_after = { 'id' => username, 'type' => 'cadet', 'badges' => [] }
      begin
        get_badges(username).each do |title, date|
          badges_after['badges'].push('id' => title, 'date' => date)
        end
        badges_after
      rescue
        nil
      end
    end

    def check_badges(usernames, badges)
      completed = {}
      missing = {}
      begin
        usernames.each do |username|
          user_results = get_badges(username)
          missing[username] = \
                  badges.reject { |badge| user_results.keys.include? badge }
          completed[username] = user_results
        end
      rescue
        halt 404
      else
        {missing: missing, completed: completed}
      end
    end

    def new_tutorial(req)
      tutorial = Tutorial.new
      tutorial.description = req['description']
      tutorial.usernames = req['usernames'].to_json
      tutorial.badges = req['badges'].to_json
      tutorial
    end
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
    user.nil? ? halt(404) : user.to_json
  end

  delete '/api/v2/tutorials/:id' do
    begin
      Tutorial.destroy(params[:id])
    rescue
      halt 404
    end
  end

  post '/api/v2/tutorials' do
    content_type :json
    body = request.body.read

    begin
      req = JSON.parse(body)
      logger.info req
    rescue Exception => e
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
    rescue => e
      halt 400, e
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
    rescue => e
      halt 400
    end

    index.to_json
  end
end
