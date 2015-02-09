# CadetDynamo
[![Codeship Status for ISS-SOA/cadet_dynamo](https://codeship.com/projects/55bae420-8357-0132-6ce1-366b1854f7f3/status?branch=master)](https://codeship.com/projects/58109)
[![Stack Share](http://img.shields.io/badge/tech-stack-0690fa.svg?style=flat)](http://stackshare.io/soumyaray/cadetdynamo)

An API web service for accessing Codecademy data (uses DynamoDB for storage)

## HTTP Routes
### API v2 Routes:
- GET /
  - returns OK status to indicate service is alive
- GET /api/v3/cadet/<username>.json
  - optional URL parameter: 'from_cache'
    - true (default): read first from cache, else scrape + encache + enqueue
    - false: scrape + encache
  - returns JSON body of user info: id (name), type, badges
  - returns status code:
    - 200 for success
    - 404 for user not found
- GET /api/v3/tutorials
  - returns JSON array of all tutorials: id, description, created_at, updated_at
  - returns status codes:
    - 200 for success
    - 400 for processing error
- POST /api/v3/tutorials
  - record tutorial request to DB
    - description (string)
    - usernames (json array)
    - badges (json array)
  - returns status code:
    - 200 for success
    - 400 for malformed JSON body elements
  - redirects to GET /api/v3/tutorials/:id
  - side effects: record created in in DynamoDB
- GET /api/v3/tutorials/:id
  - takes: id number
  - optional URL parameter: 'from_cache'
      - true (default): read first from cache, else scrape + encache + enqueue
      - false: scrape + encache
  - returns body: json of missing badges
  - returns status code:
    - 200 for success
    - 404 for resource not found
  - side effects: completed/missing results stored in DynamoDB
- DELETE /api/v3/tutorials/:id
  - takes: id # (1,2,3, etc.) of query
  - returns status code:
    - 200 for success
    - 404 for failure (not found)
- POST /api/v3/subscriber
  - record tutorial request to DB
    - description (string)
    - usernames (json array)
    - badges (json array)
  - returns status code:
    - 200 for success
    - 400 for malformed JSON body elements
    - 500 for save errors

### API v1 Routes:
- GET /*
  - returns deprecation message
  - returns status code 400


## Setup Using Rake
- Full setup: create outside resources and deploy to Heroku:
  `rake deploy:production`
- Discrete setups steps:
  - Setup outside resources: `rake deploy:resources RACK_ENV=production` calls:
    - Push credentials to Heroku:
      `rake config`
    - Create DynamoDB database for tutorial queries:
      `rake db:migrate RACK_ENV=production`
    - Create SQS queue for recent cadet queries:
      `rake queue:create RACK_ENV=production`
  - Deploy settings to Heroku:
    `rake deploy:production`

note: rake tasks require local config/config.yml outside of VCS


## Outside Services and Resources:
[![Stack Share](http://img.shields.io/badge/tech-stack-0690fa.svg?style=flat)](http://stackshare.io/soumyaray/cadetdynamo) : full list of resources

- Amazon DynamoDB: Tutorials table for storing query details
- Amazon SQS: {username, cadet_url?from_cache=false} for cadet_refresh worker
- Memcachier: (username: badges) for cacheing

External production resources are deployed on AWS region 'us-east-1'.


## Testing:

Rake task from command line:

    $ rake spec

External test resources are deployed on AWS region 'eu-central-1'.
