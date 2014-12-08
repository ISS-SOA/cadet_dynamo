require 'sinatra/base'
require 'codebadges'
require 'json'
require_relative 'model/tutorial'

##
# Fork of CadetService, using DynamoDB instead of Postgres
#
# - config: ENV vars AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION
class CadetDynamo < Sinatra::Base

  configure :production, :development do
    enable :logging
  end

  configure :development do
    set :session_secret, "something"    # ignore if not using shotgun in development
  end

  helpers do
    def user
      username = params[:username]
      return nil unless username

      badges_after = { 'id' => username, 'type' => 'cadet', 'badges' => [] }

      begin
        CodeBadges::CodecademyBadges.get_badges(username).each do |title, date|
          badges_after['badges'].push('id' => title, 'date' => date)
        end
        badges_after
      rescue
        nil
      end
    end

    def check_badges(usernames, badges)
      @incomplete = {}
      begin
        usernames.each do |username|
          badges_found = CodeBadges::CodecademyBadges.get_badges(username).keys
          @incomplete[username] = \
                  badges.reject { |badge| badges_found.include? badge }
        end
      rescue
        halt 404
      else
        @incomplete
      end
    end

    def new_tutorial(req)
      tutorial = Tutorial.new
      tutorial.description = req['description'].to_json
      tutorial.usernames = req['usernames'].to_json
      tutorial.badges = req['badges'].to_json
      tutorial
    end
  end

  get '/' do
    "#{self.name} api/v2 is up and working at /api/v2/"
  end

  # API handlers
  get '/api/v1/?*' do
    status 400
    "#{self.name} api/v1 is deprecated: please use <a href="/api/v2/">#{request.host}/api/v2/</a>"
  end

  get '/api/v2/?' do
    "#{self.name} /api/v2 is up and working"
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
    logger.info body

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
    logger.info "GET /api/v2/tutorials/#{params[:id]}"
    begin
      @tutorial = Tutorial.find(params[:id])
      usernames = JSON.parse(@tutorial.usernames)
      badges = JSON.parse(@tutorial.badges)
      logger.info({ usernames: usernames, badges: badges }.to_json)
    rescue
      halt 400
    end

    result = check_badges(usernames, badges).to_json
    logger.info "result: #{result}\n"
    result
  end
end
