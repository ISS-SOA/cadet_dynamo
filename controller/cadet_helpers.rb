require 'json'
require 'concurrent'

module CadetHelpers
  def new_tutorial(req)
    tutorial = Tutorial.new
    tutorial.description = req['description']
    tutorial.deadline = req['deadline'].try {|deadline| Date.parse deadline}
    tutorial.usernames = req['usernames'].to_json
    tutorial.badges = req['badges'].to_json
    tutorial
  end

  def get_update_tutorial_json(id)
    begin
      tutorial = Tutorial.find(id)
    rescue
      halt 404
    end

    begin
      usernames = JSON.parse(tutorial.usernames)
      badges = JSON.parse(tutorial.badges)

      results = GetCadetBadges.new.check_badges(usernames, badges, tutorial.deadline, params, settings)
      tutorial.completed = results[:completed].to_json
      tutorial.missing = results[:missing].to_json
      tutorial.late = results[:late].to_json
      tutorial.notfound = results[:notfound].to_json
      tutorial.save
      status(tutorial.notfound.empty? ? 200 : 202)
    rescue
      halt 400
    end

    tutorial
  end
end
