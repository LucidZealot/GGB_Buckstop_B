# Submission Gateway

A lightweight microservice for handling game submission data. It validates and persists submissions to a file (no database). Designed for independent use or as a proxy-backed microservice in a larger system.

## Overview
- Accepts create, update, and list requests for game submissions.
- File-backed: persists data as JSON lines (`Data/submissions.jsonl`).
- Input validation to prevent bad/malicious data.
- Runs independently (dotnet/Docker) and supports API Gateway integration.

## Key Files
- `Program.cs`: Configures services, file store, rate limiting, and endpoint registration.
- `Controllers/SubmissionsController.cs`: Defines the HTTP API (POST/PUT/GET endpoints) and input validation.
- `appsettings.json`: Controls file path for persistence under `Storage:FilePath`.
- `Data/submissions.jsonl`: Flat file storage of all submissions, created and managed at runtime.
- `Dockerfile`: Container build for shipping the service.
- `SubmissionGateway.csproj`: Project and dependency information.

## Endpoints
All datetime fields below (CreatedEst, UpdatedEst) are in US Eastern Time.

- **POST** `/api/submissions`  
  Create a new submission.  
  **Input:**
  ```json
  { "game": "string", "userId": "string", "score": 1234 }
  ```
  **Returns 201:**
  ```json
  { "id": "guid", "game": "string", "userId": "string", "score": 1234, "createdEst": "2024-06-01T18:15:04", "updatedEst": "2024-06-01T18:15:04" }
  ```
- **PUT** `/api/submissions/{id}`  
  Update score of existing submission.  
  **Input:**
  ```json
  { "score": 1500 }
  ```
- **GET** `/api/submissions/{id}`  
  Fetch a single submission by ID.  
- **GET** `/api/submissions?game=&userId=&take=`  
  List submissions:  
    - `game` = filter by game
    - `userId` = filter by user
    - `take` = max results (default 50, max 500)
  **Returns 200:** array of
  ```json
  [
    { "id": "guid", "game": "string", "userId": "string", "score": 1234, "createdEst": "...est", "updatedEst": "...est" }, 
    ...
  ]
  ```
- **Error responses:**
  - 400 validation error: `{ "error": "..." }`
  - 404 not found: `{ "error": "Submission not found" }`

## Input Validation
- `game`: Required, max 64 chars
- `userId`: Required, max 128 chars
- `score`: 0 <= score <= 1,000,000,000
- Invalid input gives 400 error

## Persistence
- Implements `ISubmissionStore` and `FileSubmissionStore` in code
- Stores each entry as 1 JSON object/line in `Data/submissions.jsonl`
- Appends a line on create, rewrites the file for updates
- File loaded into memory at startup for fast reads

## Rate Limiting
- Fixed window: 20 submissions per 10 seconds per instance

## Running the Service
- Local dev:
  ```powershell
  cd Team-3-BucStop_SubmissionGateway/SubmissionGateway
  $env:ASPNETCORE_URLS="http://localhost:8085"
  dotnet run
  ```
- Docker:
  ```sh
  docker build -t submission-gateway .
  docker run -p 8085:80 submission-gateway
  ```


## Integration (with API Gateway)
- Proxy requests by calling `/api/submissions` (POST/PUT/GET/query).
- Configure API Gateway to route those calls using `Microservices:SubmissionGateway` URL.

## Extending
- You can replace `FileSubmissionStore` by implementing `ISubmissionStore` for any storage backend (e.g., EF Core, NoSQL).
- Add new request fields by editing the models and validation logic in `Program.cs` and `Controllers/SubmissionsController.cs`.
- Enhance security with authentication, request validation schemas, or richer logging.

## Troubleshooting
- If the service doesn't store data: check write permissions for the `Data/` directory.
- If you get port errors: use a different value for `ASPNETCORE_URLS`.
- If GET/POST fails: ensure service is actually running and listening ("Now listening on …" log).
- For HTTPS, you may need to trust the .NET dev certificate: (I had this issue on my own machine)
  ```powershell
  dotnet dev-certs https --trust
  ```


