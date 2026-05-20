# Connect Scripts 

This directory contains example scripts to manipulate user-defined tables via the Connect API

## Disclaimer

> [!WARNING]
> These scripts are provided as examples only. They are not officially supported and are intended as a starting point for your own automation. No warranty is given as to their correctness or fitness for any particular purpose.
>
> Always test scripts in a non-production environment before running them against live systems. Some of these scripts may make destructive or irreversible changes (such as creating, updating or deleting definitions), so review each script carefully before use.

## Scripts

Each script has documentation at the top of the script.  Each script is also standalone and doesn't require custom modules or third-party dependencies to run.

**NOTE**: When calling these scripts you must provide the Orbit Connect API's URL for the `BaseUrl` parameter.

#### Simple single-step scripts

| Script | Synopsis |
|--------|----------|
| [ListTableDefinitions.ps1](./ListTableDefinitions.ps1) | Lists all user-defined table definitions in a DataView (requires OrbitAdmin role). |
| [GetTableDefinition.ps1](./GetTableDefinition.ps1) | Retrieves the full details of a single user-defined table definition by ID and outputs them as JSON (requires OrbitAdmin role). |
| [UpdateTableDefinition.ps1](./UpdateTableDefinition.ps1) | Updates an existing user-defined table definition by posting a JSON definition file to its Updates endpoint (requires OrbitAdmin role). |

#### Multi-step/interactive scripts

| Script | Synopsis |
|--------|----------|
| [ModifyTableDefinitionVariables.ps1](./ModifyTableDefinitionVariables.ps1) | Reads a JSON spec file describing variable changes, applies them across all matching user-defined table definitions, and posts an update for each modified definition (requires OrbitAdmin role). |