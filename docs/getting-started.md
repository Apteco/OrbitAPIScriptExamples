# Getting started

This guide takes you from getting the scripts to your first successful call to the Orbit API.

## Before you start

You need:

- PowerShell 4 or later
- An Orbit installation running Orbit API 2.3.10 or later
- An Orbit username and password for the DataView you want to work with

Some scripts, including all the Connect scripts, also need the OrbitAdmin role.

## 1. Get the scripts

Most scripts are standalone. To use one, download just that file, plus `Login.ps1` to get an access token.

The scripts in `Powershell/Workflows` combine other scripts, so they need the whole `Powershell` folder. To get everything, clone this repository, or select **Code > Download ZIP** on GitHub.

If Windows blocks the scripts because they came from the internet, unblock them:

```powershell
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
```

## 2. Find your API URLs

Orbit has separate APIs, each with its own base URL. One access token from `Login.ps1` works with all of them.

| API | Typical base URL | What it covers |
| --- | --- | --- |
| Orbit API | `https://<host>/OrbitAPI` | Dashboards, themes, audiences, users, and most other Orbit features. Most scripts use it. |
| Connect API | `https://<host>/OrbitConnectAPI` | Orbit Connect, where you build your system from your own data. The scripts in `Powershell/Connect` use it to manage user-defined table definitions. |
| Chat API | `https://<host>/ChatAPI` | The Orin AI assistant. Only `HealthCheck.ps1` uses it. |

Pass the right base URL to each script, usually with its `-BaseUrl` parameter. The scripts add the DataView name and endpoint path themselves.

## 3. Open the API reference

Add `/swagger/ui` to your Orbit API URL (for example `https://example.com/OrbitAPI/swagger/ui`) to browse every endpoint.

The page links to the API's JSON definition, at `/swagger/v2/swagger.json`. AI tools can use it to help you write new scripts. See [AI prompt ideas](ai-prompt-ideas.md).

## 4. Log in

`Login.ps1` prompts for your password and outputs an access token. Keep it in a variable:

```
> cd .\Powershell

> $token = .\Login.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -Username administrator
Enter password: *******
```

## 5. Make your first call

Pass the token to another script with `-AccessToken`. For example, list the dashboards you own:

```
> .\Dashboards\ListDashboards.ps1 -BaseUrl https://example.com/OrbitAPI -DataViewName holidays -AccessToken $token
Getting dashboards for user administrator...
1: Summary Dashboard - Spring Campaign
3: Customer Instant Insights
4: Impact Report Last Month
Got 3 dashboards
```

To check that the APIs are running and can reach their databases and services, run `HealthCheck.ps1`.

## Next steps

- [Orbit API overview](orbit-api-overview.md): how the Orbit API works, with its key endpoints
- [README](../README.md): every script in this repository
- [Combining scripts](combining-scripts.md): worked examples of using scripts together
- [AI prompt ideas](ai-prompt-ideas.md): using AI tools to write new scripts

> [!WARNING]
> These scripts are examples only, and aren't officially supported. Test them on a non-production system before you run them against live data.
