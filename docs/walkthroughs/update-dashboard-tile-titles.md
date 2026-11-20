# Change the tile titles in a dashboard

Chain four scripts in an interactive PowerShell session to change the titles of all the tiles in one dashboard. This updates the dashboard in place.

## Scripts used

- [Login.ps1](../../Powershell/Login.ps1): get an access token
- [ListDashboardUpdates.ps1](../../Powershell/Dashboards/ListDashboardUpdates.ps1): get the updates for the dashboard
- [GetDashboardUpdate.ps1](../../Powershell/Dashboards/GetDashboardUpdate.ps1): get the full JSON definition of the latest update
- [UpdateDashboard.ps1](../../Powershell/Dashboards/UpdateDashboard.ps1): save the modified definition as a new version of the dashboard

## How it works

These steps assume you already know the ID of the dashboard to change, for example 42.

1. Log in.
2. List the dashboard's updates.
3. Save the latest update's definition to a file.
4. Change the file, for example by replacing text in the title of every tile.
5. Update the dashboard from the changed definition.

> [!WARNING]
> These steps modify the dashboard in place. Test against a non-production system first,
> and check the search string is specific enough that it only matches what you intend to change.

## Example session

```
> cd .\Powershell

> $token=.\Login.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -Username myuser
Enter password: *******

> .\Dashboards\ListDashboardUpdates.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 42
Getting dashboard updates for dashboard 42...
01/01/2026 09:00:00 (update 101): Dashboard 'Life, the universe and everything' updated by myuser
01/01/2026 10:00:00 (update 102): Dashboard 'Life, the universe and everything' updated by myuser
02/01/2026 09:00:00 (update 103): Dashboard 'Life, the universe and everything' updated by myuser
03/01/2026 11:30:00 (update 104): Dashboard 'Life, the universe and everything' updated by myuser
Got 4 dashboard updates

> .\Dashboards\GetDashboardUpdate.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 42 -DashboardUpdateId 104 > C:\temp\dashboard-definition.json
Getting dashboard update 104 for dashboard 42...
Got dashboard update 104 for dashboard 42: Life, the universe and everything

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
