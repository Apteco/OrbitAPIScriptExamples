# Dashboard Themes Scripts 

This directory contains example scripts to manipulate Orbit Dashboard Themes, including for listing, creating and updating theme definitions

## Disclaimer

See the [disclaimer](../../README.md#disclaimer) in the main README.

## Scripts

Each script has documentation at the top of the script.  Each script is also standalone and doesn't require custom modules or third-party dependencies to run.

#### Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [ListDashboardThemes.ps1](./ListDashboardThemes.ps1) | Lists all dashboard themes available in a DataView. |
| [GetDashboardTheme.ps1](./GetDashboardTheme.ps1) | Retrieves the full details of a single dashboard theme by ID and outputs them as JSON. |
| [CreateDashboardTheme.ps1](./CreateDashboardTheme.ps1) | Creates a new dashboard theme by posting a JSON definition file to the API. |
| [UpdateDashboardTheme.ps1](./UpdateDashboardTheme.ps1) | Updates an existing dashboard theme by posting a JSON definition file to the theme's Updates endpoint. |