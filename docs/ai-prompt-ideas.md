# Using AI tools

Almost everything you can do in Orbit, you can do through the Orbit API, along with a few things the Orbit UI doesn't offer, such as viewing the history of changes to a dashboard or audience. An AI coding tool can help you write scripts for tasks these examples don't cover.

> [!WARNING]
> An AI tool can do anything the user it logs in as is allowed to do, including changing or deleting dashboards, audiences, or users in bulk. Only let an AI tool make live calls against a test system, and always use a user with limited access.
>
> Review and test any script an AI tool writes before you run it against live data. Like the examples here, it isn't supported by Apteco, and you're responsible for what it does when you run it.

## What to give the AI tool

- The API's definition, the `swagger.json` file from your installation. [Open the API reference](getting-started.md#open-the-api-reference) explains where to find it. It's large, so a coding agent may work better if it downloads the file first.
- One or two of the example scripts that do something similar, as a pattern to follow.
- The [Orbit API overview](orbit-api-overview.md), for how authentication, lists, and long-running jobs work.

## Tips

These come from people who have built tools on the Orbit API this way.

- Start small. Get one call working, such as logging in, before you ask for the whole tool.
- When something fails, paste the full error message back to the AI tool and let it try again.
- If the AI tool can't work out how to make a call, do the same thing in Orbit in your browser, copy the request from the browser's developer tools, and give it that. Remove the access token from the request first.
- To get data out of Orbit, point it at the Cube and Export endpoints. They return results directly, so there's no need to go through a dashboard.
- Review each change yourself. Once it works, start a new session and ask the AI tool to review the whole thing, fix any bugs it finds, and add tests.

## Example prompts

Each of these prompts asks an AI tool to write a new script, using the example scripts as a pattern.

### Transfer audience ownership

With a coding agent such as Claude Code (replace the example URL with your own):

```
Using the example scripts underneath the directory https://github.com/Apteco/OrbitAPIScriptExamples/tree/main/Powershell,
and the API definition at https://example.com/OrbitAPI/swagger/v2/swagger.json, create a
similar script to Transfer Audiences to another user.

The swagger.json definition is big - it might be beneficial to download it to a temporary location.
```

If you aren't using a coding agent, download the JSON definition and a few of the scripts, and attach them instead:

```
[Attach: swagger.json]
[Attach: TransferDashboard.ps1]
Using the attached script and swagger definition, create a similar script to Transfer Audiences to another user.
```

### Create a workspace

With a coding agent such as Claude Code (replace the example URL with your own):

```
Using the example scripts underneath the directory https://github.com/Apteco/OrbitAPIScriptExamples/tree/main/Powershell,
and the API definition at https://example.com/OrbitAPI/swagger/v2/swagger.json, create a
script to generate a workspace and add all dashboards modified today into it.

The swagger.json definition is big - it might be beneficial to download it to a temporary location.
```

### Find date and time variables

With a coding agent such as Claude Code (replace the example URL with your own):

```
Using the example scripts underneath the directory https://github.com/Apteco/OrbitAPIScriptExamples/tree/main/Powershell,
and the API definition at https://example.com/OrbitAPI/swagger/v2/swagger.json, create a
script to find all date time variables defined in the Connect system.

The swagger.json definition is big - it might be beneficial to download it to a temporary location.
```

```
Using the example scripts underneath the directory https://github.com/Apteco/OrbitAPIScriptExamples/tree/main/Powershell,
and the API definition at https://example.com/OrbitAPI/swagger/v2/swagger.json, create a
script to find all date time variables, once the system has been built from the FastStatsSystems endpoints.

The swagger.json definition is big - it might be beneficial to download it to a temporary location.
```
