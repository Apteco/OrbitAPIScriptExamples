# Orbit API Script Examples
A library of scripting examples to show some of the things that can be done with the Orbit API.

These scripts could be useful for automating administrative tasks within the Orbit platform.

## Prerequisites

All the scripts are written in Powershell and should work with Powershell 4+.  They generally require a valid access token. Use `Login.ps1` to obtain one before running any other script.

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
```

## Example usage

There are some simple single-step scripts that perform a simple action (in one or two API calls), and other scripts that perform more complex tasks in multiple steps.

For examples of how some of the simple scripts could be combined to perform more complex actions, see [docs/script-cookbook.md](docs/script-cookbook.md).

## Disclaimer

> [!WARNING]
> These scripts are provided as examples only. They are not officially supported and are intended as a starting point for your own automation. No warranty is given as to their correctness or fitness for any particular purpose.
>
> Always test scripts in a non-production environment before running them against live systems. Some of these scripts may make destructive or irreversible changes (such as creating, updating or deleting definitions), so review each script carefully before use.

## Scripts

Each script has documentation at the top of the script.  Each script is also standalone and doesn't require custom modules or third-party dependencies to run.

### Authentication

Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [Login.ps1](Powershell/Login.ps1) | Authenticates against the Orbit API and outputs an access token for use with other scripts. |

Multi-step/interactive scripts

| Script | Synopsis |
|--------|----------|
| [HealthCheck.ps1](Powershell/HealthCheck.ps1) | Runs a series of connectivity checks against the Orbit API, and optionally the Connect and Chat APIs, to verify each service is running and able to reach its dependencies. |

---

### Dashboards  *(Orbit API)*

Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [ListDashboards.ps1](Powershell/Dashboards/ListDashboards.ps1) | Lists all dashboards in a DataView that are owned by the authenticated user. |
| [ListAllDashboards.ps1](Powershell/Dashboards/ListAllDashboards.ps1) | Lists all dashboards in a DataView across all users (requires admin access). |
| [GetDashboard.ps1](Powershell/Dashboards/GetDashboard.ps1) | Retrieves details of a specific dashboard as JSON, although not full details of the items in the dashboard.  These can be looked up with the  `lastUpdateId` in combination with the `GetDashboardUpdate.ps1` script. |
| [CreateDashboard.ps1](Powershell/Dashboards/CreateDashboard.ps1) | Creates a new dashboard by posting a JSON definition file to the API. |
| [UpdateDashboard.ps1](Powershell/Dashboards/UpdateDashboard.ps1) | Updates an existing dashboard by posting a JSON definition file to the dashboard's Updates endpoint. |
| [ListDashboardUpdates.ps1](Powershell/Dashboards/ListDashboardUpdates.ps1) | Lists the full update history for a specific dashboard. |
| [GetDashboardUpdate.ps1](Powershell/Dashboards/GetDashboardUpdate.ps1) | Retrieves the full details of a specific dashboard update by dashboard ID and update ID. |

Multi-step/interactive scripts

| Script | Synopsis |
|--------|----------|
| [RevertToPreviousUpdate.ps1](Powershell/Dashboards/RevertToPreviousUpdate.ps1) | Interactively displays recent versions of a dashboard and allows the user to select one to revert to, creating a new update from the chosen historical version. |

---

### Dashboard Themes  *(Orbit API)*

Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [ListDashboardThemes.ps1](Powershell/DashboardThemes/ListDashboardThemes.ps1) | Lists all dashboard themes available in a DataView. |
| [GetDashboardTheme.ps1](Powershell/DashboardThemes/GetDashboardTheme.ps1) | Retrieves the full details of a single dashboard theme by ID and outputs them as JSON. |
| [CreateDashboardTheme.ps1](Powershell/DashboardThemes/CreateDashboardTheme.ps1) | Creates a new dashboard theme by posting a JSON definition file to the API. |
| [UpdateDashboardTheme.ps1](Powershell/DashboardThemes/UpdateDashboardTheme.ps1) | Updates an existing dashboard theme by posting a JSON definition file to the theme's Updates endpoint. |

---

### Table Definitions  *(Connect API)*

Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [ListTableDefinitions.ps1](Powershell/Connect/ListTableDefinitions.ps1) | Lists all table definitions in a DataView (requires OrbitAdmin role). |
| [GetTableDefinition.ps1](Powershell/Connect/GetTableDefinition.ps1) | Retrieves the full details of a single table definition by ID and outputs them as JSON (requires OrbitAdmin role). |
| [UpdateTableDefinition.ps1](Powershell/Connect/UpdateTableDefinition.ps1) | Updates an existing table definition by posting a JSON definition file to its Updates endpoint (requires OrbitAdmin role). |

Multi-step/interactive scripts

| Script | Synopsis |
|--------|----------|
| [ModifyTableDefinitionVariables.ps1](Powershell/Connect/ModifyTableDefinitionVariables.ps1) | Reads a JSON spec file describing variable changes, applies them across all matching table definitions, and posts an update for each modified definition (requires OrbitAdmin role). See [example-table-definition-updates-spec.json](Powershell/example-table-definition-updates-spec.json) for the spec file format. |
