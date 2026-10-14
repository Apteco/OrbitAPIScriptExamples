<#
.SYNOPSIS
    Replaces a text value in every dashboard that belongs to the current user.

.DESCRIPTION
    Logs in, lists the user's dashboards, and fetches the latest definition of
    each one. Wherever the definition contains a JSON string value that exactly
    matches FindText, it replaces it with ReplaceText and saves the result as a
    new version of the dashboard. Dashboards without a match are skipped.

    This combines Login.ps1, ListDashboards.ps1, GetDashboard.ps1,
    GetDashboardUpdate.ps1, and UpdateDashboard.ps1. The same pattern works for
    any bulk dashboard change.

.PARAMETER BaseUrl
    The base URL of the Orbit API, for example https://example.com/OrbitAPI

.PARAMETER DataViewName
    The name of the DataView to act on, for example "holidays"

.PARAMETER Username
    The username to authenticate with, whose dashboards are modified.

.PARAMETER FindText
    The text value to find. Only JSON string values that match it exactly are replaced.

.PARAMETER ReplaceText
    The text to replace it with.

.EXAMPLE
    .\Workflows\ModifyAllUserDashboards.ps1 `
        -BaseUrl "https://example.com/OrbitAPI" `
        -DataViewName "holidays" `
        -Username "administrator" `
        -FindText "Spring Campaign" `
        -ReplaceText "Summer Campaign"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$DataViewName,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$FindText,

    [Parameter(Mandatory = $true)]
    [string]$ReplaceText
)

# The building-block scripts live one folder up, in the Powershell folder
$scripts = Split-Path -Parent $PSScriptRoot

# Match whole JSON string values only, so the text isn't replaced inside
# field names or longer strings
$findPattern = '"' + [regex]::Escape($FindText) + '"'
$replacement = '"' + $ReplaceText.Replace('$', '$$') + '"'

# ---------------------------------------------------------------------------
# Step 1: Log in and get an access token
# ---------------------------------------------------------------------------
$token = & "$scripts\Login.ps1" -BaseUrl $BaseUrl -DataViewName $DataViewName -Username $Username

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Error "Login failed - no token returned."
    exit 1
}

# ---------------------------------------------------------------------------
# Step 2: List all dashboards for this user and parse their IDs
#
# ListDashboards.ps1 writes one line per dashboard in the format:
#   <id>: <title>
# We capture those lines and extract the numeric ID from the start of each.
# ---------------------------------------------------------------------------
$dashboardLines = & "$scripts\Dashboards\ListDashboards.ps1" -BaseUrl $BaseUrl -DataViewName $DataViewName -AccessToken $token

$dashboardIds = @($dashboardLines | ForEach-Object {
    if ($_ -match '^(\d+):') { $Matches[1] }
})

Write-Host "$($dashboardIds.Count) dashboard(s) found. Processing..." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Step 3: Process each dashboard
# ---------------------------------------------------------------------------
$modifiedCount = 0
$skippedCount  = 0

foreach ($dashboardId in $dashboardIds) {

    # -- 3a. Get the dashboard summary to find the current lastUpdateId ----------
    #
    # GetDashboard.ps1 outputs the dashboard object as JSON to the pipeline.
    # Write-Host status messages go to the console and aren't captured here.
    $dashboardJson  = & "$scripts\Dashboards\GetDashboard.ps1" `
                        -BaseUrl      $BaseUrl `
                        -DataViewName $DataViewName `
                        -AccessToken  $token `
                        -DashboardId  $dashboardId | Out-String

    $dashboard    = ConvertFrom-Json $dashboardJson
    $lastUpdateId = $dashboard.lastUpdateId
    $title        = $dashboard.title

    # -- 3b. Fetch the full update definition -----------------------------------
    #
    # GetDashboardUpdate.ps1 similarly outputs the update object as JSON.
    $updateJson = & "$scripts\Dashboards\GetDashboardUpdate.ps1" `
                    -BaseUrl           $BaseUrl `
                    -DataViewName      $DataViewName `
                    -AccessToken       $token `
                    -DashboardId       $dashboardId `
                    -DashboardUpdateId $lastUpdateId | Out-String

    # -- 3c. Skip if the text isn't present --------------------------------------
    if ($updateJson -notmatch $findPattern) {
        Write-Host "  [$dashboardId] $title - no match, skipping." -ForegroundColor Gray
        $skippedCount++
        continue
    }

    # -- 3d. Replace the text ----------------------------------------------------
    $modifiedJson = $updateJson -replace $findPattern, $replacement

    # -- 3e. Write to a temp file and post the update ----------------------------
    #
    # UpdateDashboard.ps1 expects a file path, so we save the JSON to a
    # temporary file and remove it once the update has been posted.
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $tempFile -Value $modifiedJson -Encoding UTF8

        & "$scripts\Dashboards\UpdateDashboard.ps1" `
            -BaseUrl           $BaseUrl `
            -DataViewName      $DataViewName `
            -AccessToken       $token `
            -DashboardId       $dashboardId `
            -DashboardJsonPath $tempFile
    }
    finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }

    Write-Host "  [$dashboardId] $title - updated." -ForegroundColor Green
    $modifiedCount++
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Done. $modifiedCount dashboard(s) updated, $skippedCount skipped." -ForegroundColor Cyan
