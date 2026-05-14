<#
.SYNOPSIS
    Lists all dashboards in a DataView that the user has access to.
 
.DESCRIPTION
    Uses a valid access token to GET the list of dashboards from /{dataViewName}/Users/{username}/Dashboards.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://cloudtest.faststats.co.uk/Develop/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.
 
.EXAMPLE
    .\ListDashboards.ps1 `
        -BaseUrl "https://cloudtest.faststats.co.uk/Develop/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here"
#>
 
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
 
    [Parameter(Mandatory = $true)]
    [string]$DataViewName,
 
    [Parameter(Mandatory = $true)]
    [string]$AccessToken
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
# Step 2: Get the list of dashboards
# ---------------------------------------------------------------------------
$dashboardsUrl  = "$BaseUrl/$DataViewName/Users/$username/Dashboards"
 
Write-Host "Getting dashboards for user $username..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}

$pageSize = 100
$offset = 0
$totalCount = 0
do
{
    try {
        $dashboardResponse = Invoke-RestMethod `
            -Uri         "$($dashboardsUrl)?offset=$offset&count=$pageSize" `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Dashboard GET failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }

    foreach ($dashboard in $dashboardResponse.list) {
        Write-Output "$($dashboard.id): $($dashboard.title)"
    }

    $offset += $pageSize
    $totalCount += $dashboardResponse.list.Count
}
while ($dashboardResponse.list.Count -gt 0)

Write-Host "Got $totalCount dashboards" -ForegroundColor Green
