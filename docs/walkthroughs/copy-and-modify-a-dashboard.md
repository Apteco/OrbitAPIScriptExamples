# Create a modified copy of a dashboard

Chain five scripts in an interactive PowerShell session to copy a dashboard with a text value replaced. The original dashboard stays unchanged.

## Scripts used

- [Login.ps1](../../Powershell/Login.ps1): get an access token
- [ListDashboards.ps1](../../Powershell/Dashboards/ListDashboards.ps1): get the IDs of the user's dashboards
- [ListDashboardUpdates.ps1](../../Powershell/Dashboards/ListDashboardUpdates.ps1): get the updates for the chosen dashboard
- [GetDashboardUpdate.ps1](../../Powershell/Dashboards/GetDashboardUpdate.ps1): get the full JSON definition of the latest update
- [CreateDashboard.ps1](../../Powershell/Dashboards/CreateDashboard.ps1): create a new dashboard from the modified definition

## How it works

1. Log in.
2. List the dashboards for the logged-in user.
3. Pick a dashboard and list its updates.
4. Save the latest update's definition to a file.
5. Change the file, for example with a search and replace on the JSON definition.
6. Create a new dashboard from the changed definition.

> [!NOTE]
> This creates a new dashboard and leaves the original unchanged. Check the new dashboard
> before you share it or delete the original.

## Example session

```
> cd .\Powershell

> $token=.\Login.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -Username myuser
Enter password: *******

> .\Dashboards\ListDashboards.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token
Getting dashboards for user myuser...
1: Summary Dashboard - Spring Campaign
3: Customer Instant Insights
4: Impact Report Last Month
Got 3 dashboards

> .\Dashboards\ListDashboardUpdates.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 3
Getting dashboard updates for dashboard 3...
01/01/2026 09:00:00 (update 101): Dashboard 'Customer Instant Insights' updated by myuser
01/01/2026 10:00:00 (update 102): Dashboard 'Customer Instant Insights' updated by myuser
02/01/2026 09:00:00 (update 103): Dashboard 'Customer Instant Insights' updated by myuser
03/01/2026 11:30:00 (update 104): Dashboard 'Customer Instant Insights' updated by myuser
Got 4 dashboard updates

> .\Dashboards\GetDashboardUpdate.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -DashboardId 3 -DashboardUpdateId 104 > C:\temp\dashboard-definition.json
Getting dashboard update 104 for dashboard 3...
Got dashboard update 104 for dashboard 3: Customer Instant Insights

> (Get-Content C:\temp\dashboard-definition.json).Replace('Customer Instant Insights', 'Renamed Dashboard') | Set-Content C:\temp\updated-dashboard-definition.json

> .\Dashboards\CreateDashboard.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token -SystemName holidays -DashboardJsonPath C:\temp\updated-dashboard-definition.json
Posting dashboard JSON from 'C:\temp\updated-dashboard-definition.json' to 'https://example.com/OrbitAPI/holidays/Dashboards'...
Dashboard Renamed Dashboard created successfully with 3 tabs!
```
