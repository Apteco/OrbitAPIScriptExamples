<#
.SYNOPSIS
    Applies a named dashboard theme to a dashboard.

.DESCRIPTION
    Looks up the ID of the theme you name, fetches the dashboard's latest
    definition, changes only its theme, and saves the result as a new version
    of the dashboard. If the dashboard already uses that theme, nothing changes.

    This combines Login.ps1, ListDashboardThemes.ps1, GetDashboard.ps1,
    GetDashboardUpdate.ps1, and UpdateDashboard.ps1.

.PARAMETER BaseUrl
    The base URL of the Orbit API, for example https://example.com/OrbitAPI

.PARAMETER DataViewName
    The name of the DataView to act on, for example "holidays"

.PARAMETER Username
    The username to authenticate with.

.PARAMETER DashboardId
    The ID of the dashboard to update.

.PARAMETER ThemeName
    The name of the theme to apply, exactly as it appears in the Orbit theme list.

.EXAMPLE
    .\Workflows\SetDashboardTheme.ps1 `
        -BaseUrl      "https://example.com/OrbitAPI" `
        -DataViewName "holidays" `
        -Username     "administrator" `
        -DashboardId  42 `
        -ThemeName    "Corporate Blue"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$DataViewName,

    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [int]$DashboardId,

    [Parameter(Mandatory = $true)]
    [string]$ThemeName
)

# The building-block scripts live one folder up, in the Powershell folder
$scripts = Split-Path -Parent $PSScriptRoot

# ---------------------------------------------------------------------------
# Step 1: Log in and get an access token
# ---------------------------------------------------------------------------
$token = & "$scripts\Login.ps1" -BaseUrl $BaseUrl -DataViewName $DataViewName -Username $Username

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Error "Login failed - no token returned."
    exit 1
}

# ---------------------------------------------------------------------------
# Step 2: List all themes and find the ID for the requested theme name
#
# ListDashboardThemes.ps1 writes one line per theme in the format:
#   <id>: <name>
# or, for the default theme:
#   <id>: <name> [DEFAULT]
# We strip the optional [DEFAULT] suffix before comparing names.
# ---------------------------------------------------------------------------
$themeLines = & "$scripts\DashboardThemes\ListDashboardThemes.ps1" -BaseUrl $BaseUrl -DataViewName $DataViewName -AccessToken $token

$targetThemeId = $null
foreach ($line in $themeLines) {
    if ($line -match '^(\d+):\s+(.+?)(\s+\[DEFAULT\])?$') {
        if ($Matches[2] -eq $ThemeName) {
            $targetThemeId = [int]$Matches[1]
            break
        }
    }
}

if ($null -eq $targetThemeId) {
    Write-Error "Theme '$ThemeName' not found. Run ListDashboardThemes.ps1 to see available themes."
    exit 1
}

Write-Host "Found theme '$ThemeName' with id $targetThemeId." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Step 3: Get the dashboard summary to find the current lastUpdateId
#
# GetDashboard.ps1 outputs the dashboard object as JSON to the pipeline.
# ---------------------------------------------------------------------------
$dashboardJson = & "$scripts\Dashboards\GetDashboard.ps1" `
                    -BaseUrl      $BaseUrl `
                    -DataViewName $DataViewName `
                    -AccessToken  $token `
                    -DashboardId  $DashboardId | Out-String

$dashboard    = ConvertFrom-Json $dashboardJson
$lastUpdateId = $dashboard.lastUpdateId
$title        = $dashboard.title

# ---------------------------------------------------------------------------
# Step 4: Fetch the full update definition
#
# GetDashboardUpdate.ps1 outputs the update object as JSON to the pipeline.
# ---------------------------------------------------------------------------
$updateJson = & "$scripts\Dashboards\GetDashboardUpdate.ps1" `
                -BaseUrl           $BaseUrl `
                -DataViewName      $DataViewName `
                -AccessToken       $token `
                -DashboardId       $DashboardId `
                -DashboardUpdateId $lastUpdateId | Out-String

$update = ConvertFrom-Json $updateJson

# ---------------------------------------------------------------------------
# Step 5: Check the current theme and skip if already correct
#
# A themeId of 0 means the dashboard is using the DataView default theme.
# ---------------------------------------------------------------------------
$currentThemeId = $update.themeId
$currentLabel   = if ($currentThemeId -eq 0) { "default (0)" } else { $currentThemeId }

if ($currentThemeId -eq $targetThemeId) {
    Write-Host "Dashboard '$title' is already using theme '$ThemeName' (id $targetThemeId). No change needed." -ForegroundColor Yellow
    exit 0
}

Write-Host "Dashboard '$title' current theme: $currentLabel. Changing to '$ThemeName' (id $targetThemeId)..." -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Step 6: Update the themeId property and re-serialise
#
# Because we're changing a specific property rather than doing a text
# substitution, we deserialise the JSON, set the property, then re-serialise.
# This avoids accidentally replacing the same value elsewhere in the document.
# ---------------------------------------------------------------------------
$update.themeId = $targetThemeId
$modifiedJson   = ConvertTo-Json -InputObject $update -Depth 100

# ---------------------------------------------------------------------------
# Step 7: Write to a temp file and post the update
# ---------------------------------------------------------------------------
$tempFile = [System.IO.Path]::GetTempFileName()
try {
    Set-Content -Path $tempFile -Value $modifiedJson -Encoding UTF8

    & "$scripts\Dashboards\UpdateDashboard.ps1" `
        -BaseUrl           $BaseUrl `
        -DataViewName      $DataViewName `
        -AccessToken       $token `
        -DashboardId       $DashboardId `
        -DashboardJsonPath $tempFile
}
finally {
    Remove-Item $tempFile -ErrorAction SilentlyContinue
}

Write-Host "Dashboard '$title' theme updated to '$ThemeName'." -ForegroundColor Green
