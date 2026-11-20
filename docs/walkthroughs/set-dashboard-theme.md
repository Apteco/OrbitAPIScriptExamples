# Set the theme for a specific dashboard

How [SetDashboardTheme.ps1](../../Powershell/Workflows/SetDashboardTheme.ps1) chains five scripts to apply a named theme to a dashboard. Rather than replacing raw text, it converts the JSON to an object, changes one property, and converts it back.

## Scripts used

- [Login.ps1](../../Powershell/Login.ps1): get an access token
- [ListDashboardThemes.ps1](../../Powershell/DashboardThemes/ListDashboardThemes.ps1): look up the ID of the named theme
- [GetDashboard.ps1](../../Powershell/Dashboards/GetDashboard.ps1): get the dashboard's details, including its `lastUpdateId`
- [GetDashboardUpdate.ps1](../../Powershell/Dashboards/GetDashboardUpdate.ps1): get the full JSON definition of that update
- [UpdateDashboard.ps1](../../Powershell/Dashboards/UpdateDashboard.ps1): save the modified definition as a new version of the dashboard

## How it works

1. Log in and capture the access token.
2. List all themes, find the one whose name matches `ThemeName`, and capture its ID.
3. Call `GetDashboard.ps1` to get the dashboard's summary, which includes `lastUpdateId`.
4. Call `GetDashboardUpdate.ps1` with that update ID to get the full JSON definition.
5. Check the current `themeId` in the definition. If it already matches the target, stop.
6. Convert the JSON to an object, set `themeId` to the theme's ID, and convert it back.
7. Write the modified JSON to a temporary file, and call `UpdateDashboard.ps1` to post it.
8. Delete the temporary file.

> [!WARNING]
> This script modifies a dashboard in place. Test against a non-production system first.

## Example output

```
> .\Workflows\SetDashboardTheme.ps1 `
      -BaseUrl      "https://example.com/OrbitAPI" `
      -DataViewName "holidays" `
      -Username     "myuser" `
      -DashboardId  42 `
      -ThemeName    "Corporate Blue"

Authenticating as 'myuser' against '...'...
Login successful. Access token obtained.
Getting dashboard themes...
Got 3 dashboard themes
Found theme 'Corporate Blue' with id 7.
Getting dashboard 42 for user myuser...
Got dashboard 42: Impact Report Last Month
Getting dashboard update 91 for dashboard 42...
Got dashboard update 91 for dashboard 42: Impact Report Last Month
Dashboard 'Impact Report Last Month' current theme: default (0). Changing to 'Corporate Blue' (id 7)...
Dashboard 'Impact Report Last Month' updated successfully with 4 tabs!
Dashboard 'Impact Report Last Month' theme updated to 'Corporate Blue'.
```

## Notes

- **Changing one property:** because the script targets one property (`themeId`) rather than doing a broad text substitution, it's safer to parse the JSON with `ConvertFrom-Json`, set the property directly, and convert it back with `ConvertTo-Json -Depth 100`. Only the intended field changes.
- **A `themeId` of 0 means the DataView default:** a value of `0` isn't an invalid ID. It's how the API signals that the dashboard uses the DataView's default theme. To go back to the default, set `ThemeName` to the theme currently marked `[DEFAULT]`, or change the target theme ID in the script to `0`.
- **Theme names match case-insensitively:** the comparison uses PowerShell's `-eq` operator, which is case-insensitive. If your theme names differ only in case, use `-ceq` instead.
