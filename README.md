# CadetDynamo
An API web service for accessing Codecademy data (uses DynamoDB for storage)

## HTTP Routes
### API v2 Routes:
- GET /
  - returns OK status to indicate service is alive
- GET /api/v2/cadet/<username>.json
  - returns JSON body of user info: id (name), type, badges
  - returns status code:
    - 200 for success
    - 404 for user not found
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
  - takes: id # (1,2,3, etc.)
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
Create DynamoDB database:

    rake db:migrate

## Testing:
**warning**: running specs wipes remote database

    rake spec
