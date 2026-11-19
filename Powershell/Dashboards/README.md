# Dashboard Scripts 

This directory contains example scripts to manipulate Orbit Dashboards, including for listing, creating and updating dashboard definitions

## Disclaimer

See the [disclaimer](../../README.md#disclaimer) in the main README.

## Scripts

Each script has documentation at the top of the script.  Each script is also standalone and doesn't require custom modules or third-party dependencies to run.

#### Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [ListDashboards.ps1](./ListDashboards.ps1) | Lists all dashboards in a DataView that are owned by the authenticated user. |
| [ListAllDashboards.ps1](./ListAllDashboards.ps1) | Lists all dashboards in a DataView across all users (requires admin access). |
| [GetDashboard.ps1](./GetDashboard.ps1) | Retrieves details of a specific dashboard as JSON, although not full details of the items in the dashboard.  These can be looked up with the `lastUpdateId` in combination with the `GetDashboardUpdate.ps1` script. |
| [CreateDashboard.ps1](./CreateDashboard.ps1) | Creates a new dashboard by posting a JSON definition file to the API. |
| [UpdateDashboard.ps1](./UpdateDashboard.ps1) | Updates an existing dashboard by posting a JSON definition file to the dashboard's Updates endpoint. |
| [ListDashboardUpdates.ps1](./ListDashboardUpdates.ps1) | Lists the full update history for a specific dashboard. |
| [GetDashboardUpdate.ps1](./GetDashboardUpdate.ps1) | Retrieves the full details of a specific dashboard update by dashboard ID and update ID. |
| [TransferDashboard.ps1](./TransferDashboard.ps1) | Transfers a dashboard from one user to another. |


#### Multi-step/interactive scripts

| Script | Synopsis |
|--------|----------|
| [RevertToPreviousUpdate.ps1](./RevertToPreviousUpdate.ps1) | Interactively displays recent versions of a dashboard and allows the user to select one to revert to, creating a new update from the chosen historical version. |


## Example usage

Each of these scripts can be used in a number of ways.  See [docs/combining-scripts.md](../../docs/combining-scripts.md) for some examples of calling multiple scripts to achieve a larger result.