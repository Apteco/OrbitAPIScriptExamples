<#
.SYNOPSIS
    Gets the latest version of a specific dashboard.  Note that this doesn't include the details of the items in the dashboard.
 
.DESCRIPTION
    Uses a valid access token to GET the latest dashboard update from /{dataViewName}/Users/{username}/Dashboards/{dashboardId}.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER DashboardId
    The ID of the dashboard to retrieve the update for.

.EXAMPLE
    .\GetDashboard.ps1 `
        -BaseUrl "https://example.com/holidays/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -DashboardId 1234
#>
 
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
 
    [Parameter(Mandatory = $true)]
    [string]$DataViewName,
 
    [Parameter(Mandatory = $true)]
    [string]$AccessToken,

    [Parameter(Mandatory = $true)]
    [int]$DashboardId
)
 
# ---------------------------------------------------------------------------
# Helper: exit with a clear error message
# ---------------------------------------------------------------------------
function Stop-WithError {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

# ---------------------------------------------------------------------------
# Helper: get session ID from JWT token
# ---------------------------------------------------------------------------
function Get-SessionIdFromToken {
    param([string]$Token)

    if (!$Token.Contains(".") -or !$Token.StartsWith("eyJ")) { 
        Stop-WithError "Invalid token $Token"
    }
    
    $tokenPayload = $Token.Split(".")[1].Replace('-', '+').Replace('_', '/')
    while ($tokenPayload.Length % 4 -ne 0) {
         $tokenPayload += "=" 
    }
    $tokenByteArray = [System.Convert]::FromBase64String($tokenPayload)
    $tokenArray = [System.Text.Encoding]::ASCII.GetString($tokenByteArray)
    $tokenJson = ConvertFrom-Json $tokenArray
    return $tokenJson.jti
}

# ---------------------------------------------------------------------------
# Step 1: Get username for current session
# ---------------------------------------------------------------------------
$sessionId = Get-SessionIdFromToken $AccessToken
if (!$sessionId) {
    Stop-WithError "Failed to get session ID from token"
}
$sessionUrl  = "$BaseUrl/$DataViewName/Sessions/$sessionId"
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}
 
try {
    $sessionResponse = Invoke-RestMethod `
        -Uri         $sessionUrl `
        -Method      GET `
        -ContentType 'application/json' `
        -Headers     $headers `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Session GET failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

$username = $sessionResponse.user.username

# ---------------------------------------------------------------------------
# Step 2: Get the details for a specific dashboard
# ---------------------------------------------------------------------------
$dashboardUrl  = "$BaseUrl/$DataViewName/Users/$username/Dashboards/$DashboardId"
 
Write-Host "Getting dashboard $DashboardId for user $username..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}

try {
    $dashboardResponse = Invoke-RestMethod `
        -Uri         "$($dashboardUrl)?includeTabDetails=false" `
        -Method      GET `
        -ContentType 'application/json' `
        -Headers     $headers `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Dashboard Update GET failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

$dashboardResponse | ConvertTo-Json -Depth 100

Write-Host "Got dashboard $($DashboardId): $($dashboardResponse.title)" -ForegroundColor Green
