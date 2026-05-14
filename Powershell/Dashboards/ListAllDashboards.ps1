<#
.SYNOPSIS
    Lists all dashboards in a DataView across all users.

.DESCRIPTION
    Uses a valid access token to GET the list of all dashboards from /{dataViewName}/Dashboards.

.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI

.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"

.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.EXAMPLE
    .\ListAllDashboards.ps1 `
        -BaseUrl "https://example.com/holidays/OrbitAPI" `
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
# Get the list of all dashboards across all users
# ---------------------------------------------------------------------------
$dashboardsUrl = "$BaseUrl/$DataViewName/Dashboards"

Write-Host "Getting all dashboards..." -ForegroundColor Cyan

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

    $page = @($dashboardResponse.list)
    foreach ($dashboard in $page) {
        $ownerName = if ($dashboard.owner) { $dashboard.owner.username } else { "<null>" }
        Write-Output "$($dashboard.id): $($dashboard.title) (owned by $ownerName)"
    }

    $offset += $pageSize
    $totalCount += $page.Count
}
while ($page.Count -gt 0)

Write-Host "Got $totalCount dashboards" -ForegroundColor Green
