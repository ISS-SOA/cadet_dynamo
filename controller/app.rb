require_relative 'cadet_helpers'
require_relative '../services/get_cadet_badges'
require_relative '../services/check_multiple_cadets'

##
# Fork of CadetService, using DynamoDB instead of Postgres
# - requires config:
#   - create ENV vars AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION
class CadetDynamo < Sinatra::Base
  helpers CadetHelpers

  show_old_version_deprecation = lambda do
    status 400
    "Version #{@ver} of CadetDynamo API is deprecated: please use " +
    "<a href=\"/api/v3/\">#{request.host}/api/v3/</a>"
  end

  show_root = lambda do
    "CadetDynamo API v3 is up and running at " +
    "<a href=\"/api/v3/\">#{request.host}/api/v3/</a>"
  end

  show_api_root = lambda do
    "CadetDynamo API v3 is up and running at " +
    "<a href=\"/api/v3/\">#{request.host}/api/v3/</a>"
  end


  get_cadet_info = lambda do
    content_type :json
    username = params[:username]
    badges = GetCadetBadges.new.call(username, params, settings)
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

  get_tutorial = lambda do
    content_type :json
    tut = get_update_tutorial_json(params[:id])
    { description: tut.description,
      deadline:    tut.deadline,
      usernames:   JSON[tut.usernames],
      badges:      JSON[tut.badges],
      completed:   JSON[tut.completed],
      missing:     JSON[tut.missing],
      late:        JSON[tut.late],
      notfound:    JSON[tut.notfound]
    }.to_json
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

  get '/api/v1/?*', &show_old_version_deprecation
  get '/api/v2/?', &show_old_version_deprecation

  get '/api/v3/?', &show_api_root
  get '/api/v3/cadet/:username.json', &get_cadet_info
  get '/api/v3/tutorials/?', &get_tutorial_index
  get '/api/v3/tutorials/:id', &get_tutorial
  post '/api/v3/tutorials', &create_tutorial_query
  delete '/api/v3/tutorials/:id', &delete_cadet
end
