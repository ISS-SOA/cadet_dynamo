require_relative './get_cadet_badges'

class CheckMultipleCadets
  def call(usernames, badges, deadline, params, settings)
    @params = params
    @settings = settings

    completed, missing, late = {}, {}, {}
    notfound = []

    threads = Concurrent::CachedThreadPool.new
    usernames.each do |username|
      threads.post do
        begin
          completed[username] = GetCadetBadges.new.call(username, @params, @settings)["badges"]
          missing[username] = badges - completed[username].keys
          if deadline
            late[username] = completed[username].select do |badge, date_completed|
              (badges.include? badge) && (date_completed > deadline)
            end
          end
        rescue
          notfound << username
        end
      end
    end
    threads.shutdown
    threads.wait_for_termination

    {missing: missing, completed: completed, late: late, notfound: notfound}
  rescue => e
    raise Exception.new("Error checking multiple cadets: #{e}")
  end
end
