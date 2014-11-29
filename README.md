# CadetService: an API for accesing Codecademy data
<!-- [ ![Codeship Status for ISS-SOA/simple_cadet](https://codeship.io/projects/e1d4f690-44bc-0132-a4ed-52edbda4e693/status?branch=master)](https://codeship.io/projects/44861) -->

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
