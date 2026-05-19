# Script Cookbook

Here are some examples showing how the individual scripts can be combined into larger workflows.

- Calling multiple scripts iteractively to create a modified copy of a dashboard
- Calling multiple scripts iteractively to programatically update a dashboard
- A single script to modify all dashboards for a user — replace a string in every dashboard definition
- A single script to set the theme for a specific dashboard

---

## Create modified dashboard copy

This example chains together five scripts in an interactive session to find and replace a text value in one
dashboard.

**Scripts used:**
- `Login.ps1` — obtain an access token
- `ListDashboards.ps1` — get all dashboard IDs for the user
- `ListDashboardUpdates.ps1` - get all the dashboard updates for thr given dashboard
- `GetDashboardUpdate.ps1` — fetch the full JSON definition for the latest update
- `CreateDashboard.ps1` — post a modified definition to create a new dashboard

### How it works

In this example the given steps are followed:
- Log in
- List all the dashboards for the logged in user
- Pick a dashboard and list all the updates for it
- Save the details of the latest dashboard update to a file
- Modify the file (e.g. do a search and replace on the JSON definition)
- Create a new dashboard from the modified definition

> [!WARNING]
> This script modifies dashboards in place. Test against a non-production system first,
> and verify the search string is specific enough that it only matches what you intend to change.

### Script

```
> cd .\Powershell

> $token=.\Login.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -Username administrator
Enter password: *******

> .\Dashboards\ListDashboards.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token
Getting dashboards for user administrator...
1: Summary Dashboard - Spring Campaign
3: Customer Instant Insights
4: Impact Report Last Month
Got 3 dashboards

> .\Dashboards\ListDashboardUpdates.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 3
Getting dashboard updates for dashboard 3...
01/01/2026 09:00:00 (update 101): Dashboard 'Customer Instant Insights' updated by administrator
01/01/2026 10:00:00 (update 102): Dashboard 'Customer Instant Insights' updated by administrator
02/01/2026 09:00:00 (update 103): Dashboard 'Customer Instant Insights' updated by administrator
03/01/2026 11:30:00 (update 104): Dashboard 'Customer Instant Insights' updated by administrator
Got 4 dashboard updates

> .\Dashboards\GetDashboardUpdate.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 3 -DashboardUpdateId 103 > C:\temp\dashboard-definition.json
Getting dashboard update 103 for dashboard 3...
Got dashboard update 103 for dashboard 3: Customer Instant Insights

> (Get-Content C:\temp\dashboard-definition.json).Replace('Customer Instant Insights', 'Renamed Dashboard') | Set-Content C:\temp\updated-dashboard-definition.json

> .\Dashboards\CreateDashboard.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -SystemName holidays -DashboardJsonPath C:\temp\updated-dashboard-definition.json
Posting dashboard JSON from 'C:\temp\updated-dashboard-definition.json' to 'https://example.com/OrbitAPI/holidays/Dashboards'...
Dashboard Renamed Dashboard created successfully with 3 tabs!
```

---

## Programmatically update a dashboard

This example chains together four scripts in an interactive session to programmatically alter all dashboard
tile titles in one dashboard

**Scripts used:**
- `Login.ps1` — obtain an access token
- `ListDashboardUpdates.ps1` - get all the dashboard updates for the given dashboard
- `GetDashboardUpdate.ps1` — fetch the full JSON definition for the latest update
- `UpdateDashboard.ps1` — post a modified definition to create a new dashboard

### How it works

In this example the given steps are followed.  It is assumed that we already know the id of the dashboard to modify (e.g. dashboard 42)
- Log in
- List all the updates for the given dashboard
- Save the details of the latest dashboard update to a file
- Modify the file (e.g. do a search and replace on the titles of all tiles in the dashboard definition)
- Create a new dashboard from the modified definition

> [!WARNING]
> This script modifies dashboards in place. Test against a non-production system first,
> and verify the search string is specific enough that it only matches what you intend to change.

### Script

```
> cd .\Powershell

> $token=.\Login.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -Username administrator
Enter password: *******

> .\Dashboards\ListDashboardUpdates.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 42
Getting dashboard updates for dashboard 3...
01/01/2026 09:00:00 (update 101): Dashboard 'Life, the universe and everything' updated by administrator
01/01/2026 10:00:00 (update 102): Dashboard 'Life, the universe and everything' updated by administrator
02/01/2026 09:00:00 (update 103): Dashboard 'Life, the universe and everything' updated by administrator
03/01/2026 11:30:00 (update 104): Dashboard 'Life, the universe and everything' updated by administrator
Got 4 dashboard updates

> .\Dashboards\GetDashboardUpdate.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 42 -DashboardUpdateId 103 > C:\temp\dashboard-definition.json
Getting dashboard update 103 for dashboard 42...
Got dashboard update 103 for dashboard 42: Life, the universe and everything

> $dashboard_definition_object = Get-Content C:\temp\dashboard-definition.json -Raw | ConvertFrom-Json
> foreach ($workbookItem in $dashboard_definition_object.workbookItems) { `
>    foreach ($tile in $workbookItem.dashboardTiles) { `
>        $tile.title = $tile.title -replace 'Arthur', 'Marvin' `
>     } `
> }
> $dashboard_definition_object | ConvertTo-Json -Depth 20 | Set-Content 'C:\temp\updated-dashboard-definition.json'

> .\Dashboards\UpdateDashboard.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 42 -DashboardJsonPath C:\temp\updated-dashboard-definition.json
Posting dashboard update JSON from 'updated-dashboard-definition.json' to 'https://example.com/OrbitAPI/holidays/Dashboards/42/Updates'...
Dashboard Life, the universe and everything updated successfully with 3 tabs!
```

## Modify all dashboards for a user — replace a string in every dashboard definition

This example chains together five scripts to find and replace a text value across every dashboard 
belonging to the current user. The same pattern can be adapted for any bulk dashboard modification.

**Scripts used:**
- `Login.ps1` — obtain an access token
- `ListDashboards.ps1` — get all dashboard IDs for the user
- `GetDashboard.ps1` — get dashboard details including its `lastUpdateId`
- `GetDashboardUpdate.ps1` — fetch the full JSON definition of that update
- `UpdateDashboard.ps1` — post the modified definition back

### How it works

1. Log in and capture the access token.
2. List all dashboards; parse the IDs from the output lines.
3. For each dashboard, call `GetDashboard.ps1` to retrieve the summary — this includes `lastUpdateId`, 
   which identifies the current live version of the dashboard definition.
4. Call `GetDashboardUpdate.ps1` with that update ID to fetch the full JSON definition.
5. Check whether `"foo"` appears in the JSON; skip the dashboard if not.
6. Replace every occurrence of `"foo"` with `"bar"` in the JSON string.
7. Write the modified JSON to a temporary file and call `UpdateDashboard.ps1` to post it.
8. Clean up the temporary file.

> [!WARNING]
> This script modifies dashboards in place. Test against a non-production system first,
> and verify the search string is specific enough that it only matches what you intend to change.

### Script

Save this alongside the other scripts in the `Powershell` directory and run it from there.

```powershell
<#
.SYNOPSIS
    Replaces all occurrences of "foo" with "bar" in every dashboard belonging to the current user.

.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI

.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"

.PARAMETER Username
    The username to authenticate with and whose dashboards will be modified.

.EXAMPLE
    .\ModifyAllUserDashboards.ps1 `
        -BaseUrl "https://example.com/holidays/OrbitAPI" `
        -DataViewName "holidays" `
        -Username "administrator"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$DataViewName,

    [Parameter(Mandatory = $true)]
    [string]$Username
)

# ---------------------------------------------------------------------------
# Step 1: Log in and obtain an access token
# ---------------------------------------------------------------------------
$token = .\Login.ps1 -BaseUrl $BaseUrl -DataViewName $DataViewName -Username $Username

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Error "Login failed — no token returned."
    exit 1
}

# ---------------------------------------------------------------------------
# Step 2: List all dashboards for this user and parse their IDs
#
# ListDashboards.ps1 writes one line per dashboard in the format:
#   <id>: <title>
# We capture those lines and extract the numeric ID from the start of each.
# ---------------------------------------------------------------------------
$dashboardLines = .\ListDashboards.ps1 -BaseUrl $BaseUrl -DataViewName $DataViewName -AccessToken $token

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
    # Write-Host status messages go to the console and are not captured here.
    $dashboardJson  = .\GetDashboard.ps1 `
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
    $updateJson = .\GetDashboardUpdate.ps1 `
                    -BaseUrl           $BaseUrl `
                    -DataViewName      $DataViewName `
                    -AccessToken       $token `
                    -DashboardId       $dashboardId `
                    -DashboardUpdateId $lastUpdateId | Out-String

    # -- 3c. Skip if the search string isn't present ---------------------------
    if ($updateJson -notmatch '"foo"') {
        Write-Host "  [$dashboardId] $title — no match, skipping." -ForegroundColor Gray
        $skippedCount++
        continue
    }

    # -- 3d. Replace "foo" with "bar" ------------------------------------------
    $modifiedJson = $updateJson -replace '"foo"', '"bar"'

    # -- 3e. Write to a temp file and post the update --------------------------
    #
    # UpdateDashboard.ps1 expects a file path, so we save the JSON to a
    # temporary file and remove it once the update has been posted.
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $tempFile -Value $modifiedJson -Encoding UTF8

        .\UpdateDashboard.ps1 `
            -BaseUrl           $BaseUrl `
            -DataViewName      $DataViewName `
            -AccessToken       $token `
            -DashboardId       $dashboardId `
            -DashboardJsonPath $tempFile
    }
    finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }

    Write-Host "  [$dashboardId] $title — updated." -ForegroundColor Green
    $modifiedCount++
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Done. $modifiedCount dashboard(s) updated, $skippedCount skipped." -ForegroundColor Cyan
```

### Example output

```
> .\ModifyAllUserDashboards.ps1 `
      -BaseUrl "https://example.com/OrbitAPI" `
      -DataViewName "holidays" `
      -Username "administrator"

Authenticating as 'administrator' against '...'...
Login successful. Access token obtained.
Getting dashboards for user administrator...
Got 3 dashboards
3 dashboard(s) found. Processing...
  [1] Summary Dashboard - Spring Campaign — no match, skipping.
  [3] Customer Instant Insights — updated.
  [4] Impact Report Last Month — updated.

Done. 2 dashboard(s) updated, 1 skipped.
```

### Notes

- **Capturing script output** — `Write-Output` (pipeline) output from a script is captured when you 
  assign the result to a variable (e.g. `$json = .\GetDashboard.ps1 ...`). `Write-Host` messages 
  go directly to the console and are not captured, so status messages from the called scripts will 
  still appear on screen while the parent script runs.

- **Temporary files** — `UpdateDashboard.ps1` takes a file path rather than a raw JSON string, 
  so a temporary file is used to pass the modified definition. The `finally` block ensures it is 
  deleted even if `UpdateDashboard.ps1` fails.

- **String replacement on raw JSON** — replacing directly in the JSON string is simple but 
  matches anywhere in the text, including inside field names and nested strings. If you need 
  more precise control (e.g. only replace within a specific field's value), deserialise with 
  `ConvertFrom-Json`, update the property, and re-serialise with `ConvertTo-Json -Depth 100` 
  before writing to the temp file.

---

## Set the theme for a specific dashboard

This example chains together five scripts to apply a named theme to a given dashboard. It
demonstrates the deserialise → modify property → re-serialise pattern as an alternative to
raw string replacement.

**Scripts used:**
- `Login.ps1` — obtain an access token
- `ListDashboardThemes.ps1` — look up the ID of the named theme
- `GetDashboard.ps1` — get dashboard details including its `lastUpdateId`
- `GetDashboardUpdate.ps1` — fetch the full JSON definition of that update
- `UpdateDashboard.ps1` — post the modified definition back

### How it works

1. Log in and capture the access token.
2. List all themes; find the one whose name matches the supplied `ThemeName` and capture its ID.
3. Call `GetDashboard.ps1` to retrieve the dashboard summary — this includes `lastUpdateId`.
4. Call `GetDashboardUpdate.ps1` with that update ID to fetch the full JSON definition.
5. Check the current `themeId` in the definition. If it already matches the target, skip.
6. Deserialise the JSON, set `themeId` to the looked-up value, and re-serialise.
7. Write the modified JSON to a temporary file and call `UpdateDashboard.ps1` to post it.
8. Clean up the temporary file.

> [!WARNING]
> This script modifies a dashboard in place. Test against a non-production system first.

### Script

Save this alongside the other scripts in the `Powershell` directory and run it from there.

```powershell
<#
.SYNOPSIS
    Sets the theme for a specific dashboard, identified by dashboard ID and theme name.

.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI

.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"

.PARAMETER Username
    The username to authenticate with.

.PARAMETER DashboardId
    The ID of the dashboard to update.

.PARAMETER ThemeName
    The name of the theme to apply, exactly as it appears in the Orbit theme list.

.EXAMPLE
    .\SetDashboardTheme.ps1 `
        -BaseUrl      "https://example.com/holidays/OrbitAPI" `
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

# ---------------------------------------------------------------------------
# Step 1: Log in and obtain an access token
# ---------------------------------------------------------------------------
$token = .\Login.ps1 -BaseUrl $BaseUrl -DataViewName $DataViewName -Username $Username

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Error "Login failed — no token returned."
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
$themeLines = .\ListDashboardThemes.ps1 -BaseUrl $BaseUrl -DataViewName $DataViewName -AccessToken $token

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
$dashboardJson = .\GetDashboard.ps1 `
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
$updateJson = .\GetDashboardUpdate.ps1 `
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
# Because we are changing a specific property rather than doing a text
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

    .\UpdateDashboard.ps1 `
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
```

### Example output

```
> .\SetDashboardTheme.ps1 `
      -BaseUrl      "https://example.com/OrbitAPI" `
      -DataViewName "holidays" `
      -Username     "administrator" `
      -DashboardId  42 `
      -ThemeName    "Corporate Blue"

Authenticating as 'administrator' against '...'...
Login successful. Access token obtained.
Getting dashboard themes...
Got 3 dashboard themes
Found theme 'Corporate Blue' with id 7.
Getting dashboard 42 for user administrator...
Got dashboard 42: Impact Report Last Month
Getting dashboard update 91 for dashboard 42...
Got dashboard update 91 for dashboard 42: Impact Report Last Month
Dashboard 'Impact Report Last Month' current theme: default (0). Changing to 'Corporate Blue' (id 7)...
Dashboard 'Impact Report Last Month' updated successfully with 4 tabs!
Dashboard 'Impact Report Last Month' theme updated to 'Corporate Blue'.
```

### Notes

- **Deserialise → modify → re-serialise** — because we are targeting a specific property 
  (`themeId`) rather than doing a broad text substitution, it is safer to parse the JSON with 
  `ConvertFrom-Json`, set the property directly, and re-serialise with `ConvertTo-Json -Depth 100`. 
  This guarantees only the intended field changes.

- **themeId 0 means the DataView default** — a value of `0` is not an invalid ID; it is how 
  the API signals that the dashboard inherits the DataView's default theme. You can restore this 
  behaviour by setting `ThemeName` to the theme currently marked `[DEFAULT]`, or by changing 
  the target theme ID to `0` in the script if you want to explicitly revert to the default.

- **Theme name matching is case-sensitive** — the comparison uses PowerShell's default `-eq` 
  operator, which is case-insensitive on Windows. If your theme names differ only in case, 
  tighten the match with `-ceq`.
