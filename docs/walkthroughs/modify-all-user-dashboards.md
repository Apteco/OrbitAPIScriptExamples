# Replace text in every dashboard you can edit

How [ModifyAllUserDashboards.ps1](../../Powershell/Workflows/ModifyAllUserDashboards.ps1) chains five scripts to find and replace a text value across every dashboard the current user can edit, including ones shared with them. The same pattern works for any bulk dashboard change.

## Scripts used

- [Login.ps1](../../Powershell/Login.ps1): get an access token
- [ListDashboards.ps1](../../Powershell/Dashboards/ListDashboards.ps1): get the IDs of the dashboards the user can see
- [GetDashboard.ps1](../../Powershell/Dashboards/GetDashboard.ps1): get each dashboard's details, including its `lastUpdateId`
- [GetDashboardUpdate.ps1](../../Powershell/Dashboards/GetDashboardUpdate.ps1): get the full JSON definition of that update
- [UpdateDashboard.ps1](../../Powershell/Dashboards/UpdateDashboard.ps1): save the modified definition as a new version of the dashboard

## How it works

1. Log in and capture the access token.
2. List all the dashboards the user can see, including shared ones, and parse the IDs from the output.
3. For each dashboard, call `GetDashboard.ps1` to get its summary. This includes `lastUpdateId`, which identifies the current version of the dashboard's definition.
4. Call `GetDashboardUpdate.ps1` with that update ID to get the full JSON definition.
5. Check whether `FindText` appears as a JSON string value, and skip the dashboard if not.
6. Replace each matching value with `ReplaceText`.
7. Write the modified JSON to a temporary file, and call `UpdateDashboard.ps1` to post it.
8. Delete the temporary file.

> [!WARNING]
> This script modifies dashboards in place. Test against a non-production system first,
> and check the search string is specific enough that it only matches what you intend to change.
>
> It also changes dashboards that other users have shared with you, if you can edit them.
> To limit what it can change, run it as a user who can edit only the dashboards you mean to update.

## Example output

```
> .\Workflows\ModifyAllUserDashboards.ps1 `
      -BaseUrl "https://example.com/OrbitAPI" `
      -DataViewName "holidays" `
      -Username "myuser" `
      -FindText "Spring Campaign" `
      -ReplaceText "Summer Campaign"

Authenticating as 'myuser' against '...'...
Login successful. Access token obtained.
Getting dashboards for user myuser...
Got 3 dashboards
3 dashboard(s) found. Processing...
  [1] Summary Dashboard - Spring Campaign - no match, skipping.
  [3] Customer Instant Insights - updated.
  [4] Impact Report Last Month - updated.

Done. 2 dashboard(s) updated, 1 skipped.
```

## Notes

- **Capturing script output:** `Write-Output` (pipeline) output from a script is captured when you assign the result to a variable (for example, `$json = .\GetDashboard.ps1 ...`). `Write-Host` messages go directly to the console and aren't captured, so status messages from the called scripts still appear on screen while the parent script runs.
- **Temporary files:** `UpdateDashboard.ps1` takes a file path rather than a raw JSON string, so a temporary file passes the modified definition. The `finally` block makes sure it's deleted even if `UpdateDashboard.ps1` fails.
- **String replacement on raw JSON:** the script only replaces JSON string values that match `FindText` exactly, so it won't change field names or longer strings that contain the text. For more precise control, such as replacing within one specific field, convert the JSON to an object with `ConvertFrom-Json`, update the property, and convert it back with `ConvertTo-Json -Depth 100` before writing the temporary file, as [SetDashboardTheme.ps1](set-dashboard-theme.md) does.
