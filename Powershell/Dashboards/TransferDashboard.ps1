<#
.SYNOPSIS
    Transfer the ownership of a dashboard to another user.
 
.DESCRIPTION
    Uses a valid access token to transfer the ownership of a dashboard to another user via /{dataViewName}/Dashboards/{dashboardId}/TransferOwnership.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER DashboardId
    The ID of the dashboard to transfer ownership for.

.PARAMETER NewOwner
    The username of the new owner of the dashboard.

.EXAMPLE
    .\TransferDashboard.ps1 `
        -BaseUrl "https://example.com/holidays/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -DashboardId 1234 `
        -NewOwner "new_owner_username"
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
    [string]$NewOwner
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
# Transfer ownership of a specific dashboard
# ---------------------------------------------------------------------------
$dashboardTransferUrl  = "$BaseUrl/$DataViewName/Dashboards/$DashboardId/TransferOwnership"
 
Write-Host "Transferring ownership of dashboard $DashboardId to $NewOwner..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}

$transferDashboardBody = @{
    newUsername = $NewOwner
}
$transferDashboardJson = $transferDashboardBody | ConvertTo-Json

try {
    $dashboardResponse = Invoke-RestMethod `
        -Uri         "$($dashboardTransferUrl)?newOwner=$NewOwner" `
        -Method      POST `
        -ContentType 'application/json' `
        -Headers     $headers `
        -Body        $transferDashboardJson `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Dashboard Transfer POST failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

Write-Host "Transferred ownership of dashboard $($DashboardId) to $($NewOwner)" -ForegroundColor Green
