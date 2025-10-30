# Acceptance Criteria Tests

This document provides the complete command sequence to prove all acceptance criteria from a fresh machine.

## Quick Start: Clean Ports Script
**Run this first if you encounter "address already in use" errors:**
```powershell
Get-NetTCPConnection -LocalPort 8081,8085 -ErrorAction SilentlyContinue | Select-Object OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }; Write-Host "Ports cleared!" -ForegroundColor Green
```

---

## Acceptance Criteria
- API endpoints allow submitting, updating, and retrieving game submission data.
- Input validation prevents invalid or malicious submissions.
- Successfully stores submission data in the persistent storage.
- Service runs independently and integrates smoothly with the main application.

---

## Prerequisites (one-time setup)
```powershell
# Trust .NET dev certificates for HTTPS (run as Admin recommended)
dotnet dev-certs https --trust
```

---

## Important: Running the Services

**You MUST run both services in separate terminal windows.** The API Gateway (port 8081) routes requests to the Submission Gateway (port 8085). Both must be running for the system to work.

**Before starting:** Make sure ports 8081 and 8085 are not in use by other applications.

---

## 0. Clear Ports (Run this FIRST if you encounter port conflicts)
If you get "address already in use" errors, run this script to free up the ports:
```powershell
# Kill any processes using ports 8081 and 8085
Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | 
    Select-Object OwningProcess -Unique | 
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

Get-NetTCPConnection -LocalPort 8085 -ErrorAction SilentlyContinue | 
    Select-Object OwningProcess -Unique | 
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

Write-Host "Ports 8081 and 8085 are now free" -ForegroundColor Green
```

---

## 1. Start Submission Gateway (independent service) - TERMINAL 1
Open a **new PowerShell terminal** and run:
```powershell
cd ".\Team-3-BucStop_SubmissionGateway\SubmissionGateway"
$env:ASPNETCORE_URLS="http://localhost:8085"
dotnet run
```
Wait for: `Now listening on: http://localhost:8085`

**Keep this terminal window open and running.**

---

## 2. Start API Gateway (integration/main app) - TERMINAL 2
Open a **second new PowerShell terminal** and run:
```powershell
cd ".\Team-3-BucStop_APIGateway\APIGateway"
$env:ASPNETCORE_URLS="http://localhost:8081"
dotnet run --no-launch-profile
```
Wait for: `Now listening on: http://localhost:8081`

**Keep this terminal window open and running.**

---

## 3. Test endpoints (submit, update, retrieve) - TERMINAL 3
Open a **third new PowerShell terminal** for testing:
```powershell
# Set base URL
$base = "http://localhost:8081"

# CREATE (POST) - proves submit endpoint
$body = @{ game="Snake"; userId="testuser1"; score=1234 } | ConvertTo-Json
$created = Invoke-RestMethod -Method Post -Uri "$base/api/submissions" -ContentType "application/json" -Body $body
$created
$id = $created.id

# RETRIEVE by ID (GET) - proves retrieve endpoint
Invoke-RestMethod -Method Get -Uri "$base/api/submissions/$id"

# UPDATE (PUT) - proves update endpoint
$updateBody = @{ score=1500 } | ConvertTo-Json
Invoke-RestMethod -Method Put -Uri "$base/api/submissions/$id" -ContentType "application/json" -Body $updateBody

# RETRIEVE again to confirm update worked
Invoke-RestMethod -Method Get -Uri "$base/api/submissions/$id"

# LIST (GET with filters) - proves list/query endpoint
Invoke-RestMethod -Method Get -Uri "$base/api/submissions?game=Snake&userId=testuser1&take=10"
```

---

## 4. Test input validation (proves validation prevents bad input) 
```powershell
# Missing required field (game)
try {
    Invoke-RestMethod -Method Post -Uri "$base/api/submissions" -ContentType "application/json" -Body (@{ userId="u1"; score=1 } | ConvertTo-Json)
} catch {
    Write-Host "Expected 400 validation error: $_" -ForegroundColor Yellow
}

# Invalid score (too high)
try {
    Invoke-RestMethod -Method Post -Uri "$base/api/submissions" -ContentType "application/json" -Body (@{ game="Snake"; userId="u1"; score=2000000000 } | ConvertTo-Json)
} catch {
    Write-Host "Expected 400 validation error: $_" -ForegroundColor Yellow
}

# Oversized game name
try {
    Invoke-RestMethod -Method Post -Uri "$base/api/submissions" -ContentType "application/json" -Body (@{ game=("A"*65); userId="u1"; score=100 } | ConvertTo-Json)
} catch {
    Write-Host "Expected 400 validation error: $_" -ForegroundColor Yellow
}
```

---

## 5. Verify persistent storage
```powershell
# Check file exists and contains data (run from project root directory)
Get-Content "Team-3-BucStop_SubmissionGateway\SubmissionGateway\Data\submissions.jsonl"
```
You should see JSON lines representing the submissions created above. Each line is a complete JSON object with fields like `id`, `game`, `userId`, `score`, `createdEst`, and `updatedEst`.

---

## 6. Confirm integration (already tested in steps 3-4)
The fact that you called `http://localhost:8081/api/submissions` (API Gateway) and it successfully routed to the Submission Gateway proves smooth integration.

---
## Summary
- ✓ Endpoints work (POST/PUT/GET)
- ✓ Validation prevents bad input
- ✓ Data persisted to file
- ✓ Service runs independently and integrates via API Gateway


## Troubleshooting

### Error: "address already in use" or "Failed to bind to address"
**Problem:** Port 8081 or 8085 is already in use by another process.

**Solution:** Run the port cleanup script from **Step 0** or the Quick Start section at the top of this document:
```powershell
Get-NetTCPConnection -LocalPort 8081,8085 -ErrorAction SilentlyContinue | 
    Select-Object OwningProcess -Unique | 
    ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }
```
Then try starting the services again.

### Error: "Could not copy apphost.exe" or "file is locked"
**Problem:** A previous instance is still running and locking the executable.

**Solution:** Stop all SubmissionGateway and APIGateway processes:
```powershell
Get-Process -Name "SubmissionGateway","APIGateway","dotnet" -ErrorAction SilentlyContinue | Stop-Process -Force
```

### Error: 404 Not Found when testing endpoints
**Problem:** One or both services are not running.

**Solution:** 
1. Verify both services are running in their respective terminals
2. Check that you see "Now listening on: http://localhost:8085" in Terminal 1
3. Check that you see "Now listening on: http://localhost:8081" in Terminal 2
4. Make sure you're sending requests to `http://localhost:8081` (API Gateway), not 8085

### Build Errors
**Problem:** Code compilation errors.

**Solution:** Ensure all code changes are saved and try:
```powershell
dotnet clean
dotnet build
```

If errors persist, check that:
- All `using` statements are present
- The `Program.CurrentEasternTime()` method is in a `partial Program` class
- All property initializers use `Program.CurrentEasternTime()` instead of `CurrentEasternTime()`

