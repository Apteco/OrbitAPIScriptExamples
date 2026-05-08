<#
.SYNOPSIS
    Reverts a dashboard to a previous update.

.DESCRIPTION
    Fetches the most recent N updates for a dashboard (where N is HistoryLength), displays
    details including timestamp, title, creator, number of tabs (workbook items) and tiles
    per tab, then prompts the user to select a version to revert to. If confirmed, creates
    a new dashboard update based on the definition of the selected historical version.

.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://cloudtest.faststats.co.uk/Develop/OrbitAPI

.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"

.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER DashboardId
    The ID of the dashboard to revert.

.PARAMETER HistoryLength
    The number of recent updates to display. Defaults to 3.

.EXAMPLE
    .\RevertToPreviousUpdate.ps1 `
        -BaseUrl "https://cloudtest.faststats.co.uk/Develop/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -DashboardId 1234

.EXAMPLE
    .\RevertToPreviousUpdate.ps1 `
        -BaseUrl "https://cloudtest.faststats.co.uk/Develop/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -DashboardId 1234 `
        -HistoryLength 5
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

    [Parameter(Mandatory = $false)]
    [int]$HistoryLength = 3
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
# Fetch the most recent dashboard updates (summary list)
# ---------------------------------------------------------------------------
$dashboardUpdatesUrl = "$BaseUrl/$DataViewName/Dashboards/$DashboardId/Updates"

Write-Host "Fetching the $HistoryLength most recent updates for dashboard $DashboardId..." -ForegroundColor Cyan

$headers = @{
    Authorization = "Bearer $AccessToken"
}

try {
    $updatesResponse = Invoke-RestMethod `
        -Uri         "$($dashboardUpdatesUrl)?offset=0&count=$($HistoryLength + 1)&orderBy=-Timestamp" `
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

$recentUpdates = $updatesResponse.list

if ($recentUpdates.Count -eq 0) {
    Write-Host "No updates found for dashboard $DashboardId." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Fetch full details (with tab and tile info) for each recent update
# ---------------------------------------------------------------------------
Write-Host "Fetching details for $($recentUpdates.Count) update(s)..." -ForegroundColor Cyan

$updateDetails = @()
foreach ($update in $recentUpdates) {
    try {
        $detail = Invoke-RestMethod `
            -Uri         "$($dashboardUpdatesUrl)/$($update.id)?includeTabDetails=true" `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "Dashboard Update GET failed for update $($update.id) (HTTP $statusCode). Response: $errorBody`nError: $_"
    }
    $updateDetails += $detail
}

# ---------------------------------------------------------------------------
# Display the version history
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Recent updates for dashboard $DashboardId" -ForegroundColor White
Write-Host ("=" * 50) -ForegroundColor DarkGray

$index = 0
foreach ($detail in $updateDetails) {
    $tabs = if ($detail.workbookItems) { @($detail.workbookItems) } else { @() }
    $totalTiles = 0
    foreach ($tab in $tabs) {
        if ($tab.dashboardTiles) { $totalTiles += @($tab.dashboardTiles).Count }
    }

    Write-Host ""
    if ($index -eq 0) {
        Write-Host "[NOW] Update ID  : $($detail.id)" -ForegroundColor White
    }
    else {
        Write-Host "  [$index] Update ID  : $($detail.id)" -ForegroundColor White
    }
    Write-Host "      Timestamp  : $($detail.timestamp)" -ForegroundColor Gray
    Write-Host "      Title      : $($detail.title)" -ForegroundColor Gray
    Write-Host "      Created by : $($detail.user.username)" -ForegroundColor Gray
    Write-Host "      Tabs       : $($tabs.Count)   Total tiles: $totalTiles" -ForegroundColor Gray

    $tabIndex = 1
    foreach ($tab in $tabs) {
        $tileCount = if ($tab.dashboardTiles) { @($tab.dashboardTiles).Count } else { 0 }
        $tabLabel  = if ($tab.title) { $tab.title } else { "Tab $tabIndex" }
        Write-Host "        - $tabLabel`: $tileCount tile(s)" -ForegroundColor DarkGray
        $tabIndex++
    }

    $index++
}

Write-Host ""
Write-Host ("=" * 50) -ForegroundColor DarkGray
Write-Host ""

# ---------------------------------------------------------------------------
# Prompt user to select a version
# ---------------------------------------------------------------------------
$choice = Read-Host "Enter the number of the version to revert to (1-$($updateDetails.Count - 1)), or press Enter to cancel"

if ([string]::IsNullOrWhiteSpace($choice)) {
    Write-Host "No version selected. Exiting without changes." -ForegroundColor Yellow
    exit 0
}

$choiceInt = 0
if (-not [int]::TryParse($choice, [ref]$choiceInt) -or $choiceInt -lt 1 -or $choiceInt -gt $updateDetails.Count) {
    Stop-WithError "Invalid selection '$choice'. Please enter a number between 1 and $($updateDetails.Count)."
}

$selectedUpdate = $updateDetails[$choiceInt]

Write-Host ""
Write-Host "Selected: update $($selectedUpdate.id) from $($selectedUpdate.timestamp), created by $($selectedUpdate.user.username)." -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Revert dashboard $DashboardId to this version? (y/n)"

if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Revert cancelled. Exiting without changes." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Post the selected update as a new dashboard update
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Reverting dashboard $DashboardId to the version from update $($selectedUpdate.id)..." -ForegroundColor Cyan

$selectedUpdate.id             = $DashboardId
$selectedUpdate.timestamp      = $null
$selectedUpdate.hasSolutionTile = $null
$revertJson = ConvertTo-Json -InputObject $selectedUpdate -Depth 100

try {
    $revertResponse = Invoke-RestMethod `
        -Uri         $dashboardUpdatesUrl `
        -Method      POST `
        -ContentType 'application/json' `
        -Headers     $headers `
        -Body        $revertJson `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Dashboard revert POST failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

$newTabCount = if ($revertResponse.workbookItems) { @($revertResponse.workbookItems).Count } else { 0 }
Write-Host "Dashboard '$($revertResponse.title)' successfully reverted! New update ID: $($revertResponse.id). Tabs: $newTabCount." -ForegroundColor Green
