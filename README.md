# CadetDynamo
[ ![Codeship Status for ISS-SOA/cadet_dynamo](https://codeship.com/projects/55bae420-8357-0132-6ce1-366b1854f7f3/status?branch=master)](https://codeship.com/projects/58109)
[![Stack Share](http://img.shields.io/badge/tech-stack-0690fa.svg?style=flat)](http://stackshare.io/soumyaray/cadetdynamo)

An API web service for accessing Codecademy data (uses DynamoDB for storage)

## HTTP Routes
### API v2 Routes:
- GET /
  - returns OK status to indicate service is alive
- GET /api/v2/cadet/<username>.json
  - optional URL parameter: 'from_cache'
    - true (default): read first from cache, else scrape + encache + enqueue
    - false: scrape + encache
  - returns JSON body of user info: id (name), type, badges
  - returns status code:
    - 200 for success
    - 404 for user not found
- GET /api/v2/tutorials
  - returns JSON array of all tutorials: id, description, created_at, updated_at
  - returns status codes:
    - 200 for success
    - 400 for processing error
- POST /api/v2/tutorials
  - record tutorial request to DB
    - description (string)
    - usernames (json array)
    - badges (json array)
  - returns status code:
    - 200 for success
    - 400 for malformed JSON body elements
  - redirects to GET /api/v2/tutorials/:id
  - side effects: record created in in DynamoDB
- GET /api/v2/tutorials/:id
  - takes: id number
  - optional URL parameter: 'from_cache'
      - true (default): read first from cache, else scrape + encache + enqueue
      - false: scrape + encache
  - returns body: json of missing badges
  - returns status code:
    - 200 for success
    - 404 for resource not found
  - side effects: completed/missing results stored in DynamoDB
- DELETE /api/v2/tutorials/:id
  - takes: id # (1,2,3, etc.) of query
  - returns status code:
    - 200 for success
    - 404 for failure (not found)
- POST /api/v2/subscriber
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

## Setup
  - Create DynamoDB database:
    `rake db:migrate`
  - Create SQS queue for recent cadet queries:
    `rake queue:create`
  - Deploy settings to Heroku:
    `rake deploy`

## Outside Services:
- Amazon DynamoDB
- Amazon SQS
- Memcachier

External resources (production) are deployed on 'us-east-1' region of AWS:

## Testing:

Rake task from command line:

    $ rake spec

External resources (test) are deployed on 'eu-central-1' region of AWS.
