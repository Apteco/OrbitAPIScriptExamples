# Dashboard Themes Scripts 

This directory contains example scripts to manipulate Orbit Dashboard Themes, including for listing, creating and updating theme definitions

## Disclaimer

> [!WARNING]
> These scripts are provided as examples only. They are not officially supported and are intended as a starting point for your own automation. No warranty is given as to their correctness or fitness for any particular purpose.
>
> Always test scripts in a non-production environment before running them against live systems. Some of these scripts may make destructive or irreversible changes (such as creating, updating or deleting definitions), so review each script carefully before use.

## Scripts

Each script has documentation at the top of the script.  Each script is also standalone and doesn't require custom modules or third-party dependencies to run.

#### Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [ListDashboardThemes.ps1](Powershell/DashboardThemes/ListDashboardThemes.ps1) | Lists all dashboard themes available in a DataView. |
| [GetDashboardTheme.ps1](Powershell/DashboardThemes/GetDashboardTheme.ps1) | Retrieves the full details of a single dashboard theme by ID and outputs them as JSON. |
| [CreateDashboardTheme.ps1](Powershell/DashboardThemes/CreateDashboardTheme.ps1) | Creates a new dashboard theme by posting a JSON definition file to the API. |
| [UpdateDashboardTheme.ps1](Powershell/DashboardThemes/UpdateDashboardTheme.ps1) | Updates an existing dashboard theme by posting a JSON definition file to the theme's Updates endpoint. |