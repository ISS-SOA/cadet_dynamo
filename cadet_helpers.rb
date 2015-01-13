module CadetHelpers
  def from_cache?
    cacheing_param = params[:from_cache]
    (cacheing_param && cacheing_param.downcase == 'false') ? false : true
  end

  def scrape_badges(username)
    CodeBadges::CodecademyBadges.get_badges username
  end

  def enqueue_cadet(username)
    settings.cadet_queue.send_message(username)
  rescue => e
    logger.error "Cadet cacheing failed: #{e}"
  end

  def encache_cadet(username, badges)
    settings.cadet_cache.set username, badges
  end

  def get_cached_badges(username)
    settings.cadet_cache.fetch(username, ttl=settings.cadet_cache_ttl) do
      (scrape_badges username).tap { |badges| enqueue_cadet(username) if badges }
    end
  rescue
    scrape_badges username
  end

  def get_badges(username)
    if from_cache?
      get_cached_badges(username)
    else
      scrape_badges(username).tap { |badges| encache_cadet username, badges }
    end
  end

  def get_user_badges
    return nil unless username = params[:username]
    badges = get_badges(username).map do |title, date|
      {'id' => title, 'date' => date}
    end
    { 'id' => username, 'type' => 'cadet', 'badges' => badges }
  rescue
    nil
  end

  def check_badges(usernames, badges)
    completed, missing = {}, {}
    usernames.each do |username|
      completed[username] = get_badges(username)
      # missing[username] = badges.reject { |badge| completed[username].keys.include? badge }
      missing[username] = badges - completed[username].keys
    end
    {missing: missing, completed: completed}
  rescue
    halt 404
  end

  def new_tutorial(req)
    tutorial = Tutorial.new
    tutorial.description = req['description']
    tutorial.usernames = req['usernames'].to_json
    tutorial.badges = req['badges'].to_json
    tutorial
  end
end
