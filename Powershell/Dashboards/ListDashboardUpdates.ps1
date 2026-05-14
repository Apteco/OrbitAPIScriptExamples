<#
.SYNOPSIS
    Lists all updates a dashboard has been through.
 
.DESCRIPTION
    Uses a valid access token to GET the list of dashboard updates from /{dataViewName}/Dashboards/{dashboardId}/Updates.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://cloudtest.faststats.co.uk/Develop/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER DashboardId
    The ID of the dashboard to retrieve updates for.

.EXAMPLE
    .\ListDashboardUpdates.ps1 `
        -BaseUrl "https://cloudtest.faststats.co.uk/Develop/OrbitAPI" `
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
# Get the list of dashboard updates
# ---------------------------------------------------------------------------
$dashboardUpdatesUrl  = "$BaseUrl/$DataViewName/Dashboards/$DashboardId/Updates"
 
Write-Host "Getting dashboard updates for dashboard $DashboardId..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}

$pageSize = 100
$offset = 0
$totalCount = 0
do
{
    try {
        $dashboardUpdatesResponse = Invoke-RestMethod `
            -Uri         "$($dashboardUpdatesUrl)?offset=$offset&count=$pageSize" `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Dashboard Updates GET failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }

    foreach ($dashboardUpdate in $dashboardUpdatesResponse.list) {
        Write-Output "$($dashboardUpdate.timestamp) (update $($dashboardUpdate.id)): Dashboard '$($dashboardUpdate.title)' updated by $($dashboardUpdate.user.username)"
    }

    $offset += $pageSize
    $totalCount += $dashboardUpdatesResponse.list.Count
}
while ($dashboardUpdatesResponse.list.Count -gt 0)

Write-Host "Got $totalCount dashboard updates" -ForegroundColor Green
