<#
.SYNOPSIS
    Gets a specific update of a dashboard.
 
.DESCRIPTION
    Uses a valid access token to GET a specific dashboard update from /{dataViewName}/Dashboards/{dashboardId}/Updates/{dashboardUpdateId}.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER DashboardId
    The ID of the dashboard to retrieve the update for.

.PARAMETER DashboardUpdateId
    The ID of the dashboard update to retrieve.


.EXAMPLE
    .\GetDashboardUpdate.ps1 `
        -BaseUrl "https://example.com/holidays/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -DashboardId 1234 `
        -DashboardUpdateId 5678
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
    [int]$DashboardUpdateId
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
# Get a specific dashboard update
# ---------------------------------------------------------------------------
$dashboardUpdateUrl  = "$BaseUrl/$DataViewName/Dashboards/$DashboardId/Updates/$DashboardUpdateId"
 
Write-Host "Getting dashboard update $DashboardUpdateId for dashboard $DashboardId..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}

try {
    $dashboardUpdateResponse = Invoke-RestMethod `
        -Uri         "$($dashboardUpdateUrl)?includeTabDetails=true" `
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

$dashboardUpdateResponse | ConvertTo-Json -Depth 100

Write-Host "Got dashboard update $($dashboardUpdateResponse.id) for dashboard $($DashboardId): $($dashboardUpdateResponse.title)" -ForegroundColor Green
