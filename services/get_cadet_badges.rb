require 'codebadges'

class Cacheing
  attr_reader :required
  alias_method :required?, :required

  def initialize(http_params)
    @required = !!(http_params['from_cache'] &&
                  (http_params['from_cache'].downcase == 'true'))
  end
end

class GetCadetBadges
  def call(username, params, settings)
    return nil unless username
    @cacheing = Cacheing.new(params)
    @settings = settings
    badges = get_badges(username).map do |title, date|
      # {'id' => title, 'date' => date}
      [title, date]
    end.to_h
    { 'id' => username, 'type' => 'cadet', 'badges' => badges }
  rescue
    nil
  end

  private

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
    if @cacheing.required?
      get_cached_badges(username)
    else
      scrape_badges(username).tap { |badges| encache_cadet username, badges }
    end
  end
end
