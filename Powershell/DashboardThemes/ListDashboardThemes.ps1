<#
.SYNOPSIS
    Lists all dashboard themes in a DataView.
 
.DESCRIPTION
    Uses a valid access token to GET the list of dashboard themes from /{dataViewName}/Themes.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://cloudtest.faststats.co.uk/Develop/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.
 
.EXAMPLE
    .\ListDashboardThemes.ps1 `
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
# Step 2: Get the list of dashboard themes
# ---------------------------------------------------------------------------
$themesUrl  = "$BaseUrl/$DataViewName/Themes"
 
Write-Host "Getting dashboard themes..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}

try {
    $themeResponse = Invoke-RestMethod `
        -Uri         $themesUrl `
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

foreach ($theme in $themeResponse) {
    $isDefault = if ($theme.default) { " [DEFAULT]" } else { "" }
    Write-Output "$($theme.id): $($theme.name)$isDefault"
}

Write-Host "Got $($themeResponse.list.Count) dashboard themes" -ForegroundColor Green
