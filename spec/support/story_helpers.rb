module StoryHelpers
  def random_str(n)
    (0..n).map { ('a'..'z').to_a[rand(26)] }.join
  end
end

def check_tutorial_redirect_url(url, header, body)
  post url, body.to_json, header
  last_response.must_be :redirect?
  last_response.location.tap { |l| l.must_match %r"#{url}/.+" }
end

def check_tutorial_request_params(url, base_url, valid_body)
  tut_id = url.scan(%r"#{base_url}/(.+)").flatten[0]
  saved_tutorial = Tutorial.find(tut_id)
  JSON.parse(saved_tutorial.usernames).must_equal valid_body[:usernames]
  JSON.parse(saved_tutorial.badges).must_include valid_body[:badges][0]
end

def get_tutorial_redirect_results
  follow_redirect!
  JSON.parse last_response.body
end
