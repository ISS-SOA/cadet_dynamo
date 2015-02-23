require_relative 'spec_helper'
require_relative 'support/story_helpers'
require 'json'

describe 'CadetDynamo Stories' do
  include StoryHelpers

  describe 'Getting the root of the service' do
    it 'should return ok' do
      get '/'
      last_response.must_be :ok?
    end
  end

  describe 'Getting single cadet badges' do
    it 'should return single cadet badges' do
      get '/api/v3/cadet/soumya.ray.json'
      last_response.must_be :ok?
    end

    it 'should return single cadet badges when from_cache=false' do
      get '/api/v3/cadet/soumya.ray.json?from_cache=false'
      last_response.must_be :ok?
    end

    it 'should return 404 for unknown user' do
      get "/api/v3/cadet/#{random_str(20)}.json"
      last_response.must_be :not_found?
    end

    it 'should return 404 for unkown user when from_cache=false' do
      get "/api/v3/cadet/#{random_str(20)}.json?from_cache=false"
      last_response.must_be :not_found?
    end
  end

  describe 'Checking group of users' do
    before do
      Tutorial.delete_all
    end

    it 'should find missing badges with all params given' do
      url = '/api/v3/tutorials'
      header = { 'CONTENT_TYPE' => 'application/json' }
      valid_body = {
        description: 'Check valid users and badges',
        deadline: Date.today.to_s,
        usernames: ['soumya.ray', 'chenlizhan'],
        badges: ['Object-Oriented Programming II']
      }

      next_location = check_tutorial_redirect_url(url, header, valid_body)
      check_tutorial_request_params(next_location, valid_body)
      results = check_tutorial_find_results

      results['missing']['soumya.ray'].must_equal valid_body[:badges]
      Date.parse(results['deadline']).must_equal Date.today
    end

    it 'should find missing badges with optional params missing' do
      valid_header = { 'CONTENT_TYPE' => 'application/json' }
      valid_body = {
        usernames: ['soumya.ray', 'chenlizhan'],
        badges: ['Object-Oriented Programming II']
      }

      # Check redirect URL from post request
      post '/api/v3/tutorials', valid_body.to_json, valid_header
      last_response.must_be :redirect?
      next_location = last_response.location
      next_location.must_match /api\/v3\/tutorials\/.+/

      # Check if request parameters are stored in ActiveRecord data store
      tut_id = next_location.scan(/tutorials\/(.+)/).flatten[0]
      saved_tutorial = Tutorial.find(tut_id)
      JSON.parse(saved_tutorial.usernames).must_equal valid_body[:usernames]
      JSON.parse(saved_tutorial.badges).must_include valid_body[:badges][0]

      # Check if redirect works
      follow_redirect!
      last_request.url.must_match /api\/v3\/tutorials\/.+/

      # Check if correct results returned
      results = JSON.parse last_response.body
      results['missing']['soumya.ray'].must_equal valid_body[:badges]
      results['description'].must_be_nil
      results['deadline'].must_be_nil
    end

    it 'should return 404 for unknown users' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = {
        description: 'Check invalid users and invalid badges',
        usernames: [random_str(15), random_str(15)],
        badges: [random_str(30)]
      }

      post '/api/v3/tutorials', body.to_json, header

      last_response.must_be :redirect?
      follow_redirect!
      last_response.must_be :not_found?
    end

    it 'should return 400 for bad JSON formatting' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = random_str(50)

      post '/api/v3/tutorials', body, header
      last_response.must_be :bad_request?
    end

    it 'should be able to delete a previous query' do
      header = { 'CONTENT_TYPE' => 'application/json' }
      body = {
        description: 'Check valid users and badges',
        usernames: ['soumya.ray', 'chenlizhan'],
        badges: ['Object-Oriented Programming II']
      }

      # Check redirect URL from post request
      post '/api/v3/tutorials', body.to_json, header
      last_response.must_be :redirect?
      next_location = last_response.location
      next_location.must_match /api\/v3\/tutorials\/.+/

      # Check if request parameters are stored in ActiveRecord data store
      tut_id = next_location.scan(/tutorials\/(.+)/).flatten[0]
      delete "/api/v3/tutorials/#{tut_id}"
      last_response.must_be :ok?
    end

    it 'should report error if deleting an unknown entry' do
      delete "/api/v3/tutorials/55555"
      last_response.must_be :not_found?
    end
  end
end
