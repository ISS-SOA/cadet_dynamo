require 'json'

require 'active_support'
require 'active_support/core_ext'

module CadetHelpers
  def from_cache?
    cacheing = params['from_cache']
    (cacheing && cacheing.downcase == 'false') ? false : true
  end

  def scrape_badges(username)
    CodeBadges::CodecademyBadges.get_badges username
  end

  def enqueue_cadet(username)
    queue = settings.cadet_queue.queues.named(settings.cadet_queue_name)

    cadet_url = URI.join('http://'+@HOST_WITH_PORT+'/', "api/#{@ver}/",
                          'cadet/', "#{username}.json?from_cache=false").to_s
    message = { username: username, url: cadet_url }
    result = queue.send_message(message.to_json)
  rescue => e
    logger.error "ENQUEUE_CADET failed: #{e}"
  end

  def encache_cadet(username, badges)
    settings.cadet_cache.set(username, badges, ttl=settings.cadet_cache_ttl)
  rescue => e
    logger.info "ENCACHE_CADET failed: #{e}"
  end

  def scrape_enqueue_cadet(username)
    (scrape_badges username).tap { |badges| enqueue_cadet(username) if badges }
  rescue => e
    logger.info "SCRAPE_ENQUEUE_CADET failed: #{e}"
  end

  def get_cached_badges(username)
    settings.cadet_cache.fetch(username, ttl=settings.cadet_cache_ttl) do
      scrape_enqueue_cadet username
    end
  rescue => e
    logger.info "GET_CACHED_BADGES failed: #{e}"
    scrape_enqueue_cadet username
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

  def check_badges(usernames, badges, deadline)
    completed, missing, late = {}, {}, {}
    usernames.each do |username|
      completed[username] = get_badges(username)
      missing[username] = badges - completed[username].keys
      if deadline
        late[username] = completed[username].select do |badge, date_completed|
          (badges.include? badge) && (date_completed > deadline)
        end
      end
    end
    {missing: missing, completed: completed, late: late}
  rescue
    halt 404
  end

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

      results = check_badges(usernames, badges, tutorial.deadline)
      tutorial.completed = results[:completed].to_json
      tutorial.missing = results[:missing].to_json
      tutorial.late = results[:late].to_json
      tutorial.save
    rescue
      halt 400
    end

    tutorial
  end
end
