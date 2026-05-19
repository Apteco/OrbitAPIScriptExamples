# Dashboard Script 

This directory contains example scripts to manipulate Orbit Dashboards, including for listing, creating and updating dashboard definitions

## Disclaimer

> [!WARNING]
> These scripts are provided as examples only. They are not officially supported and are intended as a starting point for your own automation. No warranty is given as to their correctness or fitness for any particular purpose.
>
> Always test scripts in a non-production environment before running them against live systems. Some of these scripts may make destructive or irreversible changes (such as creating, updating or deleting definitions), so review each script carefully before use.

## Scripts

Each script has documentation at the top of the script.  Each script is also standalone and doesn't require custom modules or third-party dependencies to run.

Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [ListDashboards.ps1](./ListDashboards.ps1) | Lists all dashboards in a DataView that are owned by the authenticated user. |
| [ListAllDashboards.ps1](./ListAllDashboards.ps1) | Lists all dashboards in a DataView across all users (requires admin access). |
| [GetDashboard.ps1](./GetDashboard.ps1) | Retrieves details of a specific dashboard as JSON, although not full details of the items in the dashboard.  These can be looked up with the  `lastUpdateId` in combination with the `GetDashboardUpdate.ps1` script. |
| [CreateDashboard.ps1](./CreateDashboard.ps1) | Creates a new dashboard by posting a JSON definition file to the API. |
| [UpdateDashboard.ps1](./UpdateDashboard.ps1) | Updates an existing dashboard by posting a JSON definition file to the dashboard's Updates endpoint. |
| [ListDashboardUpdates.ps1](./ListDashboardUpdates.ps1) | Lists the full update history for a specific dashboard. |
| [GetDashboardUpdate.ps1](./GetDashboardUpdate.ps1) | Retrieves the full details of a specific dashboard update by dashboard ID and update ID. |
| [TransferDashboard.ps1](./TransferDashboard.ps1) | Transfer a  dashboard from one user to another. |


Multi-step/interactive scripts

| Script | Synopsis |
|--------|----------|
| [RevertToPreviousUpdate.ps1](./RevertToPreviousUpdate.ps1) | Interactively displays recent versions of a dashboard and allows the user to select one to revert to, creating a new update from the chosen historical version. |


## Example usage

Each of these scripts can be used in a number of ways:
- See [docs/dashboards-example-usage.md](../../docs/dashboards-example-usage.md) for some examples of calling scripts one after the other interactively.
- Alternatively see [docs/script-cookbook.md](../../docs/script-cookbook.md) for examples of how to take the essence of these scripts and write a single master script that calls multiple endpoints to achieve a complex outcome.