<#
.SYNOPSIS
    Gets a particular dashboard theme from a DataView.
 
.DESCRIPTION
    Uses a valid access token to GET a dashboard theme from /{dataViewName}/Themes/{themeId}.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/Holidays/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER ThemeId
    The ID of the dashboard theme to retrieve.

.EXAMPLE
    .\GetDashboardTheme.ps1 `
        -BaseUrl "https://example.com/Holidays/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -ThemeId 12345
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
    [int]$ThemeId
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
# Get the dashboard theme
# ---------------------------------------------------------------------------
$themeUrl  = "$BaseUrl/$DataViewName/Themes/$ThemeId"
 
Write-Host "Getting dashboard theme..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}

try {
    $themeResponse = Invoke-RestMethod `
        -Uri         $themeUrl `
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

Write-Output $themeResponse | ConvertTo-Json -Depth 10

Write-Host "Got dashboard theme $($themeResponse.id): $($themeResponse.name)" -ForegroundColor Green
