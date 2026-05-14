<#
.SYNOPSIS
    Performs a few checks against the OrbitAPI, ConnectAPI and ChatAPI to check that they are healthy
 
.DESCRIPTION
    Uses a valid access token to POST a JSON file to /{dataViewName}/Themes.
 
.PARAMETER OrbitBaseUrl
    The base URL of the Orbit API, e.g. https://example.com/Holidays/OrbitAPI

.PARAMETER ConnectBaseUrl
    The base URL of the Connect API, e.g. https://example.com/Holidays/OrbitConnectAPI.  Can be omitted if ConnectAPI checks are not required.

.PARAMETER ChatBaseUrl
    The base URL of the Chat API, e.g. https://example.com/Holidays/ChatAPI.  Can be omitted if ChatAPI checks are not required.

.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.EXAMPLE
    .\HealthCheck.ps1 `
        -OrbitBaseUrl "https://www.example.com/OrbitAPI" `
        -ConnectBaseUrl "https://www.example.com/OrbitConnectAPI" `
        -ChatBaseUrl "https://www.example.com/ChatAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here"
#>
 
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$OrbitBaseUrl,
 
    [Parameter(Mandatory = $false)]
    [string]$ConnectBaseUrl,
 
    [Parameter(Mandatory = $false)]
    [string]$ChatBaseUrl,
 
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
# Check Orbit API version
# ---------------------------------------------------------------------------
$orbitApiVersionUrl = "$OrbitBaseUrl/About/Version"
 
Write-Host "Checking Orbit API version at '$orbitApiVersionUrl'..." -ForegroundColor Cyan
 
try {
    $versionResponse = Invoke-RestMethod `
        -Uri         $orbitApiVersionUrl `
        -Method      GET `
        -ContentType 'application/json' `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Orbit API version check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}
 
Write-Host "✅ Orbit API version check successful (version $($versionResponse.version))." -ForegroundColor Green
Write-Host "   - Orbit API process is running" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Get username for current session
# ---------------------------------------------------------------------------
$sessionId = Get-SessionIdFromToken $AccessToken
if (!$sessionId) {
    Stop-WithError "Failed to get session ID from token"
}
$orbitApiSessionUrl  = "$OrbitBaseUrl/$DataViewName/Sessions/$sessionId"

Write-Host "Checking Orbit API user details at '$orbitApiSessionUrl'..." -ForegroundColor Cyan

$headers = @{
    Authorization = "Bearer $AccessToken"
}
 
try {
    $sessionResponse = Invoke-RestMethod `
        -Uri         $orbitApiSessionUrl `
        -Method      GET `
        -ContentType 'application/json' `
        -Headers     $headers `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Orbit API user details check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

$username = $sessionResponse.user.username
Write-Host "✅ Orbit API user details check successful (found user '$username')." -ForegroundColor Green
Write-Host "   - Orbit API can connect to Global Users database" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Get aiId for current user
# ---------------------------------------------------------------------------
$orbitApiUserUrl  = "$OrbitBaseUrl/$DataViewName/Users/$username"

Write-Host "Checking Orbit API user details at '$orbitApiUserUrl'..." -ForegroundColor Cyan

$headers = @{
    Authorization = "Bearer $AccessToken"
}
 
try {
    $userResponse = Invoke-RestMethod `
        -Uri         $orbitApiUserUrl `
        -Method      GET `
        -ContentType 'application/json' `
        -Headers     $headers `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Orbit API user details check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

$aiId = $userResponse.licence.aiId
Write-Host "✅ Orbit API user details check successful (found user '$username' with AI Id '$aiId')." -ForegroundColor Green
Write-Host "   - Orbit API can connect to Orbit database" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Check FastStats Systems in DataView (verifies Orbit API can talk to databse and FS Service)
# ---------------------------------------------------------------------------
$orbitApiSystemsUrl = "$OrbitBaseUrl/$DataViewName/FastStatsSystems"
 
Write-Host "Checking Orbit API FastStats systems at '$orbitApiSystemsUrl'..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}

try {
    $systemsResponse = Invoke-RestMethod `
        -Uri         $orbitApiSystemsUrl `
        -Method      GET `
        -ContentType 'application/json' `
        -Headers     $headers `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Orbit API FastStats systems check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}
 
Write-Host "✅ Orbit API FastStats systems check successful (found $($systemsResponse.list.Count) systems)." -ForegroundColor Green
Write-Host "   - Orbit API can connect to Job Queue database and FastStats Services responding" -ForegroundColor Green
$systemName = ""
if ($systemsResponse.list.Count -gt 0) {
  $systemName = $systemsResponse.list[0].name
  Write-Host "  First FastStats system: $($systemsResponse.list[0].name) (view name $($systemsResponse.list[0].viewName)) built on $($systemsResponse.list[0].fastStatsBuildDate)" -ForegroundColor Green
}

if ($ConnectBaseUrl) {
    # ---------------------------------------------------------------------------
    # Check Connect API version
    # ---------------------------------------------------------------------------
    $connectApiVersionUrl = "$ConnectBaseUrl/About/Version"
    
    Write-Host "Checking Connect API version at '$connectApiVersionUrl'..." -ForegroundColor Cyan
    
    try {
        $versionResponse = Invoke-RestMethod `
            -Uri         $connectApiVersionUrl `
            -Method      GET `
            -ContentType 'application/json' `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Connect API version check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }
    
    Write-Host "✅ Connect API version check successful (version $($versionResponse.version))." -ForegroundColor Green
    Write-Host "   - Connect API process is running" -ForegroundColor Green

    # ---------------------------------------------------------------------------
    # Check Connect Users (verifies Connect API can talk to Orbit API)
    # ---------------------------------------------------------------------------
    $connectApiUsersUrl = "$ConnectBaseUrl/Users"
    
    Write-Host "Checking Connect API users at '$connectApiUsersUrl'..." -ForegroundColor Cyan

    $headers = @{
        Authorization = "Bearer $AccessToken"
    }

    try {
        $usersResponse = Invoke-RestMethod `
            -Uri         $connectApiUsersUrl `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Connect API users check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }
    
    Write-Host "✅ Connect API users check successful (username $($usersResponse.username))." -ForegroundColor Green
    Write-Host "   - Connect API can connect to Orbit API" -ForegroundColor Green

    # ---------------------------------------------------------------------------
    # Check Connect Settings (verifies Connect API can talk to Database)
    # ---------------------------------------------------------------------------

    $connectApiSettingsUrl = "$ConnectBaseUrl/$DataViewName/Settings"
    
    Write-Host "Checking Connect API settings at '$connectApiSettingsUrl'..." -ForegroundColor Cyan

    $headers = @{
        Authorization = "Bearer $AccessToken"
    }

    try {
        $settingsResponse = Invoke-RestMethod `
            -Uri         $connectApiSettingsUrl `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Connect API settings check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }
    
    Write-Host "✅ Connect API settings check successful." -ForegroundColor Green
    Write-Host "   - Connect API can connect to database" -ForegroundColor Green
}

if ($ChatBaseUrl) {
    # ---------------------------------------------------------------------------
    # Check Chat API version
    # ---------------------------------------------------------------------------
    $chatApiVersionUrl = "$ChatBaseUrl/About/Version"
    
    Write-Host "Checking Chat API version at '$chatApiVersionUrl'..." -ForegroundColor Cyan
    
    try {
        $versionResponse = Invoke-RestMethod `
            -Uri         $chatApiVersionUrl `
            -Method      GET `
            -ContentType 'application/json' `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Chat API version check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }
    
    Write-Host "✅ Chat API version check successful (version $($versionResponse.version))." -ForegroundColor Green
    Write-Host "   - Chat API process is running" -ForegroundColor Green

    # ---------------------------------------------------------------------------
    # Check Chat Message Usage (verifies Chat API can talk to Apteco Services)
    # ---------------------------------------------------------------------------
    $chatApiUsageUrl = "$ChatBaseUrl/$DataViewName/Chat/MessageUsage?aiId=$aiId"
 
    Write-Host "Checking Chat API message usage at '$chatApiUsageUrl'..." -ForegroundColor Cyan

    $headers = @{
        Authorization = "Bearer $AccessToken"
    }

    try {
        $usageResponse = Invoke-RestMethod `
            -Uri         $chatApiUsageUrl `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Chat API message usage check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }
    
    Write-Host "✅ Chat API message usage check successful ($($usageResponse.chatMessagesRemaining) messages remaining from $($usageResponse.chatMessagesLimit))." -ForegroundColor Green
    Write-Host "   - Chat API can connect to Apteco AI Proxy infrastructure" -ForegroundColor Green

    # ---------------------------------------------------------------------------
    # Check Chat Conversation History (verifies Chat API can talk to Database)
    # ---------------------------------------------------------------------------
    $chatApiHistoryUrl = "$ChatBaseUrl/$DataViewName/Chat/$systemName/ChatHistory/$username/ConversationHistory"
    
    Write-Host "Checking Chat API conversation history at '$chatApiHistoryUrl'..." -ForegroundColor Cyan

    $headers = @{
        Authorization = "Bearer $AccessToken"
    }

    try {
        $historyResponse = Invoke-RestMethod `
            -Uri         $chatApiHistoryUrl `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Chat API conversation history check failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }
    
    Write-Host "✅ Chat API conversation history check successful ($($historyResponse.totalCount) messages with history)." -ForegroundColor Green
    Write-Host "   - Chat API can connect to Orbit database" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Complete
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "***********************************************" -ForegroundColor Green
Write-Host "** All health checks completed successfully. **" -ForegroundColor Green
Write-Host "***********************************************" -ForegroundColor Green
