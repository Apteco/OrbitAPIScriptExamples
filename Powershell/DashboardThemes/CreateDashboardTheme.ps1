<#
.SYNOPSIS
    Posts a dashboard theme JSON file to the Apteco Orbit API.
 
.DESCRIPTION
    Uses a valid access token to POST a JSON file to /{dataViewName}/Themes.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://cloudtest.faststats.co.uk/Develop/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.
 
.PARAMETER ThemeJsonPath
    The path to the JSON file to post to the Themes endpoint.
 
.EXAMPLE
    .\CreateDashboardTheme.ps1 `
        -BaseUrl "https://cloudtest.faststats.co.uk/Develop/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
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
$themeUrl  = "$BaseUrl/$DataViewName/Themes"
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

Write-Host "Theme $($themeResponse.name) (ID: $($themeResponse.id)) created successfully!" -ForegroundColor Green
