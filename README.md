# CadetDynamo: an API for accessing Codecademy data (uses DynamoDB for storate)

API v2 Routes:
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
- GET /api/v2/tutorials/:id
  - takes: id # (1,2,3, etc.)
  - returns body: json of missing badges
  - returns status code:
    - 200 for success
    - 404 for resource not found
- DELETE /api/v2/tutorials/:id
  - takes: id # (1,2,3, etc.) of query
  - returns status code:
    - 200 for success
    - 404 for failure (not found)

API v1 Routes:
- GET /*
  - returns deprecation message
  - returns status code 400
