<#
.SYNOPSIS
    Posts a JSON file to update an existing dashboard theme in the Apteco Orbit API.
 
.DESCRIPTION
    Uses a valid access token to POST a JSON file to /{dataViewName}/Themes/{themeId}/Updates.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.
 
.PARAMETER ThemeId
    The ID of the dashboard theme to update.
 
.PARAMETER ThemeJsonPath
    The path to the JSON file to post to the Themes endpoint.

.EXAMPLE
    .\UpdateDashboardTheme.ps1 `
        -BaseUrl "https://example.com/holidays/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -ThemeId 12345 `
        -ThemeJsonPath ".\theme.json"
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
    [int]$ThemeId,
 
    [Parameter(Mandatory = $true)]
    [string]$ThemeJsonPath
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
# Validate the theme JSON file exists
# ---------------------------------------------------------------------------
if (-not (Test-Path -Path $ThemeJsonPath -PathType Leaf)) {
    Stop-WithError "Theme JSON file not found: $ThemeJsonPath"
}
 
# ---------------------------------------------------------------------------
# Post the theme JSON
# ---------------------------------------------------------------------------
$themeUrl  = "$BaseUrl/$DataViewName/Themes/$ThemeId/Updates"
$themeJson = Get-Content -Path $ThemeJsonPath -Raw
 
Write-Host "Posting theme JSON from '$ThemeJsonPath' to '$themeUrl'..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}
 
try {
    $themeResponse = Invoke-RestMethod `
        -Uri         $themeUrl `
        -Method      POST `
        -ContentType 'application/json' `
        -Headers     $headers `
        -Body        $themeJson `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Theme POST failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

Write-Host "Theme $($themeResponse.name) (ID: $($themeResponse.id)) updated successfully!" -ForegroundColor Green
