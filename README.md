# CadetService: an API for accesing Codecademy data
[ ![Codeship Status for ISS-SOA/cadet_service](https://codeship.com/projects/9ad845e0-5a86-0132-729a-46545b4ba6c4/status)](https://codeship.com/projects/50387)

API v2 Routes:
- GET /
  - returns OK status to indicate service is alive
- GET /api/v2/cadet/<username>.json
  - returns JSON of user info: id (name), type, badges
- POST /api/v2/tutorials
  - record tutorial request to DB
    - description (string)
    - usernames (json array)
    - badges (json array)
  - redirects to GET /api/v2/tutorials/:id
- GET /api/v2/tutorials/:id
  - takes: id # (1,2,3, etc.)
  - returns: json of missing badges
- DELETE /api/v2/tutorials/:id
  - takes: id # (1,2,3, etc.) of query
  - returns 200 OK for success
