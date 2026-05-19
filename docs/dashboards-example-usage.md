# Dashboard Scripts Examples

Each of the dashboard scripts can be used in a number of ways, but here are a number of examples of how some of the scripts might be combined.

## Create modified dashboard copy

In this example the given steps are followed:
- Log in
- List all the dashboards for the logged in user
- Pick a dashboard and list all the updates for it
- Save the details of the latest dashboard update to a file
- Modify the file (e.g. do a search and replace on the JSON definition)
- Create a new dashboard from the modified definition

The commands to do this (plus example output) would be:

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

## Programmatically update a dashboard

In this example the given steps are followed.  It is assumed that we already know the id of the dashboard to modify (e.g. dashboard 42)
- Log in
- List all the updates for the given dashboard
- Save the details of the latest dashboard update to a file
- Modify the file (e.g. do a search and replace on the titles of all tiles in the dashboard definition)
- Create a new dashboard from the modified definition

The commands to do this (plus example output) would be:

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