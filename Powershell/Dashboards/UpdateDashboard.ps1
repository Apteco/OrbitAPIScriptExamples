<#
.SYNOPSIS
    Posts a dashboard JSON file to the Apteco Orbit API to update an existing dashboard.
 
.DESCRIPTION
    Uses a valid access token to POST a JSON file to /{dataViewName}/Dashboards/{dashboardId}/Updates.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/Holidays/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.
 
.PARAMETER DashboardId
    The ID of the dashboard to update.

.PARAMETER DashboardJsonPath
    The path to the JSON file to post to the Dashboards endpoint.
 
.EXAMPLE
    .\UpdateDashboard.ps1 `
        -BaseUrl "https://example.com/Holidays/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -DashboardId 1234 `
        -DashboardJsonPath ".\dashboard.json"
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
    [int]$DashboardId,

    [Parameter(Mandatory = $true)]
    [string]$DashboardJsonPath
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
# Validate the dashboard JSON file exists
# ---------------------------------------------------------------------------
if (-not (Test-Path -Path $DashboardJsonPath -PathType Leaf)) {
    Stop-WithError "Dashboard JSON file not found: $DashboardJsonPath"
}
 
# ---------------------------------------------------------------------------
# Post the dashboard update JSON
# ---------------------------------------------------------------------------
$dashboardUrl  = "$BaseUrl/$DataViewName/Dashboards/$DashboardId/Updates"
$dashboardJson = Get-Content -Path $DashboardJsonPath -Raw

$dashboardUpdate = ConvertFrom-Json -InputObject $dashboardJson
$dashboardUpdate.id = $DashboardId
$dashboardUpdate.timestamp = $null
$dashboardUpdate.hasSolutionTile = $null
$dashboardJson = ConvertTo-Json -InputObject $dashboardUpdate -Depth 100

Write-Host "Posting dashboard update JSON from '$DashboardJsonPath' to '$dashboardUrl'..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}
 
try {
    $dashboardResponse = Invoke-RestMethod `
        -Uri         $dashboardUrl `
        -Method      POST `
        -ContentType 'application/json' `
        -Headers     $headers `
        -Body        $dashboardJson `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Dashboard Update POST failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

Write-Host "Dashboard $($dashboardResponse.title) updated successfully with $($dashboardResponse.workbookItems.length) tabs!" -ForegroundColor Green
