require 'codebadges'

class GetCadetBadges
  def call(params, settings)
    @params = params
    @settings = settings
    return nil unless username = @params[:username]
    badges = get_badges(username).map do |title, date|
      {'id' => title, 'date' => date}
    end
    { 'id' => username, 'type' => 'cadet', 'badges' => badges }
  rescue
    nil
  end

  def check_badges(usernames, badges, deadline, params, settings)
    @params = params
    @settings = settings

    completed, missing, late = {}, {}, {}
    notfound = []

    threads = Concurrent::CachedThreadPool.new
    usernames.each do |username|
      threads.post do
        begin
          completed[username] = get_badges(username)
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
    halt "#{e}"
  end

  private

  def from_cache?
    cacheing = @params['from_cache']
    (cacheing && cacheing.downcase == 'false') ? false : true
  end

  def scrape_badges(username)
    CodeBadges::CodecademyBadges.get_badges username
  end

  def enqueue_cadet(username)
    queue = @settings.cadet_queue.queues.named(@settings.cadet_queue_name)

    cadet_url = URI.join('http://'+@HOST_WITH_PORT+'/', "api/#{@ver}/",
                          'cadet/', "#{username}.json?from_cache=false").to_s
    message = { username: username, url: cadet_url }
    result = queue.send_message(message.to_json)
  rescue => e
    logger.error "ENQUEUE_CADET failed: #{e}"
  end

  def encache_cadet(username, badges)
    @settings.cadet_cache.set(username, badges, ttl=@settings.cadet_cache_ttl)
  rescue => e
    logger.info "ENCACHE_CADET failed: #{e}"
  end

  def scrape_enqueue_cadet(username)
    (scrape_badges username).tap { |badges| enqueue_cadet(username) if badges }
  rescue => e
    logger.info "SCRAPE_ENQUEUE_CADET failed: #{e}"
  end

  def get_cached_badges(username)
    @settings.cadet_cache.fetch(username, ttl=@settings.cadet_cache_ttl) do
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
end
