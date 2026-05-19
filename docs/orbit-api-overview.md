# Orbit API Overview

The **Apteco Orbit API** provides programmatic access to the Orbit platform. It covers managing Orbit Audiences, Dashboard and Campaigns, Variable and Table metadata and User management, amongst other things.

- **Base URL:** This is typically `https://<host>/OrbitAPI/` (such as `https://example.com/OrbitAPI`).
- **Swagger specification:** If the OrbitAPI base URL is `https://example.com/OrbitAPI`, then the swagger specification JSON document will be available at `https://example.com/OrbitAPI/swagger/v2/swagger.json`
- **Authentication:** Session-based using a Bearer token. Tokens can be obtained via the `Sessions` endpoints.

## Key Principles and Patterns

There are some key ideas and shared patterns used across the API:

- **Data Views** - Most resources are grouped in to Data Views, and so a `{dataViewName}` is often required as part of the API endpoint URL.
- **Systems** - A Data View can contain one or more systems and many endpoints require the system name to be specified as well as the Data View.
- **Async job pattern** — Long-running operations follow a consistent three-step pattern:
  1. `POST .../XxxJobs` — Submit the job and receive a `jobId`.
  2. `GET .../XxxJobs/{jobId}` — Poll for status and results.
  3. `DELETE .../XxxJobs/{jobId}` — Cancel a running job.
  
  Some operations also offer a synchronous variant (`POST .../XxxSync`) that blocks until complete, accepting a `timeoutInSeconds` query parameter.
- **OrbitAdmin role** — Admin-scoped list and write endpoints (e.g. listing all audiences across the DataView, managing themes, channels, and settings) require the `OrbitAdmin` role.
- **Filtering, paging and sorting** - Many endpoints that return a list of resources can be filtered, paged and sorted in a consistent way:
  - **filter** - Specify a `filter` query string parameter to specify a filter expression.  This will be of the form `field eq "value"` or `(a < 123) and (b > 456)`.  Each endpoint will have a different set of fields that can be filtered on, documented in the endpoint's Swagger description.
  - **offset** and **count** - Specifying an `offset` query string parameter will allow you to skip the first n results.  In combination with a `count` query string parameter (which sets the maximum number of results to return) this allows you to define a page of results.  For example, if you had 25 results to show and you wanted to show these as pages of 10 you could show the first page with a query string of `?offset=0&count=10`, the second page with `?offset=10&count=10` and the last page (with only 5 results) as `?offset=20&count=10`.
  - **orderBy** - Specify an `orderBy` query string parameter to sort by the values for one field (again from the list of fields documented in the endpoint's Swagger description).  To sort ascending use the field's name (i.e. `?orderBy=Username`) and to sort descending add a minus sign to the front of the field's name (i.e. `?orderBy=-Username`)

  An example of filtering, paging and sorting when listing all Users in the "holidays" DataView might use a GET request to the URL: `https://example.com/OrbitAPI/holidays/Users?filter=LastAccessDate%20gt%20'2026-01-01'&offset=0&count=10&orderBy=Surname`

## Significant endpoints

Each of the endpoints in the Orbit API has a function and use-case, but some of the more widely applicable endpoints fall into the following categories: 

- Sessions
- Users
- Audiences
- Dashboards
- Campaigns
- Sharing
- FastStats System

A summary for some of the important endpoints in these categories are listed below.  For detailed information about each endpoint or the list of other endpoints refer to the Swagger documentation.

---

### Sessions

A series of endpoints that allow for session management, including logging in and out.

#### Sessions endpoints

| Method   | Path | Description |
|----------|------|-------------|
| `POST`   | `/Sessions/SimpleLogin` | Creates a session using a plain username and password |
| `POST`   | `/Sessions/ConvertSession` | Converts a legacy FastStats session ID into an API access token |
| `GET`    | `/Sessions/{sessionId}` | Gets basic user details for a given session |
| `GET`    | `/Sessions/{sessionId}/Valid` | Checks whether a given session ID is still valid |
| `DELETE` | `/Sessions/{sessionId}` | Logs out and invalidates the specified session |
| `POST`   | `/Sessions/Mfa/Totp/Verify` | Verifies a TOTP code during the MFA login flow |
| `POST`   | `/Sessions/Mfa/RecoveryCode/Verify` | Verifies a recovery code during the MFA login flow |
| `POST`   | `/Sessions/Mfa/Totp/Setup` | Initiates TOTP MFA setup — returns a secret and QR code URI |
| `POST`   | `/Sessions/Mfa/Totp/Setup/Verify` | Completes TOTP MFA setup and returns a full session on success |
| `GET`    | `/Sessions` | Lists all currently active sessions *(OrbitAdmin only)* |


### Users

A series of endpoints that allow for getting information on users within Data Views, managing their group memberships and system access, and listing the resources they own.

#### User account endpoints

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/Users` | List all users in the DataView |
| `POST`   | `/Users` | Create a new user |
| `GET`    | `/Users/{username}` | Get details for a specific user |
| `POST`   | `/Users/{username}` | Update details for a specific user |
| `DELETE` | `/Users/{username}` | Delete a user |
| `POST`   | `/Users/{username}/ChangePassword` | Change the password for a user |
| `POST`   | `/Users/{username}/Groups` | Modify which groups a user belongs to |
| `POST`   | `/Users/{username}/Systems` | Modify which systems a user has access to |
| `GET`    | `/Users/{username}/LoginHistory` | Get the login history for a user |

#### User resources endpoints

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/Users/{username}/ResourceCounts` | Get a count of all resources (audiences, dashboards, collections, etc.) owned by a user |
| `PUT`    | `/Users/ResourcesTransferOwnership` | Transfer all resources owned by one user to another user |
| `GET`    | `/Users/{username}/Audiences` | List audiences owned by a user |
| `POST`   | `/Users/{username}/Audiences/Modify` | Update one or more audiences for a user |
| `GET`    | `/Users/{username}/Dashboards` | List dashboards owned by a user |
| `POST`   | `/Users/{username}/Dashboards/Modify` | Update one or more dashboards for a user |
| `GET`    | `/Users/Favourites/{systemName}` | Get the active user's favourites for a system |
| `POST`   | `/Users/{username}/Favourites/Modify` | Update favourites for a user |

### Audiences

A series of endpoints that allow for retreiving and modifying Orbit Audiences and for retreiving and modifying favourites used to create audience workbook items.

#### Audiences endpoints
| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/Audiences` | List all audiences in the DataView *(OrbitAdmin only)* |
| `POST`   | `/Audiences` | Create a new audience |
| `GET`    | `/Audiences/{audienceId}` | Get full details of an audience (optionally include queries, brief, workbook items) |
| `POST`   | `/Audiences/{audienceId}/Copy` | Duplicate an existing audience |
| `POST`   | `/Audiences/{audienceId}/TransferOwnership` | Transfer ownership to another user |
| `GET`    | `/Audiences/{audienceId}/Updates` | List all saved updates (versions) of an audience |
| `POST`   | `/Audiences/{audienceId}/Updates` | Save a new update (modified version) of an audience |
| `GET`    | `/Audiences/{audienceId}/Updates/{audienceUpdateId}` | Get details of a specific audience version |
| `GET`    | `/Audiences/{audienceId}/AudienceWorkbookItemDetails/{id}` | Get details of a workbook item within an audience |

#### Favourites endpoints
| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/Users/Favourites/{systemName}` | Get all favourites for the currently logged-in user |
| `GET`    | `/Users/Favourites/{systemName}/{id}` | Get a specific favourite by ID |
| `POST`   | `/Favourites/{systemName}` | Create a new favourite |
| `POST`   | `/Favourites/{systemName}/Duplicate` | Duplicate an existing favourite (provide `favouriteId` and `newTitle`) |
| `POST`   | `/Favourites/{systemName}/Rename` | Rename or update the description of a favourite |
| `POST`   | `/Users/{username}/Favourites/Modify` | Modify the set of favourites for a specific user |


### Dashboards

A series of endpoints that allow for retreiving and modifying Orbit Dashboards and for retreiving and modifying themes used within dashboards.

#### Dashboards endpoints

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/Dashboards` | List all dashboards in the DataView *(OrbitAdmin only)* |
| `POST`   | `/Dashboards` | Create a new dashboard |
| `DELETE` | `/Dashboards/{dashboardId}` | Delete a dashboard |
| `POST`   | `/Dashboards/{dashboardId}/Copy` | Duplicate an existing dashboard |
| `POST`   | `/Dashboards/{dashboardId}/TransferOwnership` | Transfer ownership to another user |
| `GET`    | `/Dashboards/{dashboardId}/Updates` | List all saved versions of a dashboard |
| `POST`   | `/Dashboards/{dashboardId}/Updates` | Save a new version of a dashboard |
| `GET`    | `/Dashboards/{dashboardId}/Updates/{dashboardUpdateId}` | Get details of a specific dashboard version (optionally include tab details) |

#### Themes endpoints

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/Themes` | List all themes available in the DataView |
| `POST`   | `/Themes` | Create a new theme *(OrbitAdmin only)* |
| `GET`    | `/Themes/{themeId}` | Get details of a specific theme |
| `DELETE` | `/Themes/{themeId}` | Delete a theme *(OrbitAdmin only)* |
| `POST`   | `/Themes/{themeId}/Updates` | Update the details of a theme *(OrbitAdmin only)* |


### Campaigns

A series of endpoints that allow for getting information about Orbit Campaigns (under the PeopleStage name).

#### PeopleStage system endpoints

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/PeopleStage` | List FastStats systems that have PeopleStage configured |
| `GET`    | `/PeopleStage/{systemName}` | Get PeopleStage details for a system |
| `POST`   | `/PeopleStage/{systemName}/RefreshSync` | Refresh the PeopleStage diagram (sync) |
| `POST`   | `/PeopleStage/{systemName}/PauseSystem` | Pause all processing on a PeopleStage system |
| `POST`   | `/PeopleStage/{systemName}/ResumeSystem` | Resume processing on a paused PeopleStage system |

#### PeopleStage element endpoints

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/PeopleStage/{systemName}/Elements` | List root-level PeopleStage elements |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}` | Get details of a specific element |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/Children` | List the children of an element |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/Status` | Get the current status of an element |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/Status/Descendants` | Get status of all descendant elements |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/RunningSteps` | List steps currently running within an element |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/CompletedSteps` | List steps that have completed within an element |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/RunningDeliveries` | List delivery actions currently running |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/CompletedDeliveries` | List delivery actions that have completed |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/CommunicationStats` | Get communication volume statistics over time |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/ChannelStats` | Get total communications sent per channel |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/ResponseStats` | Get response statistics per channel |
| `GET`    | `/PeopleStage/{systemName}/Elements/{elementId}/RangeStats/Sync` | Get statistics for a given date range (sync) |
| `POST`   | `/PeopleStage/{systemName}/Elements/{elementId}/PublishJobs` | Async: publish (activate) an element |
| `POST`   | `/PeopleStage/{systemName}/Elements/{elementId}/Pause` | Pause a running campaign or diagram |
| `POST`   | `/PeopleStage/{systemName}/Elements/{elementId}/Resume` | Resume a paused campaign or diagram |
| `POST`   | `/PeopleStage/{systemName}/Elements/{elementId}/DrainJobs` | Async: drain queued records from a campaign node |
| `POST`   | `/PeopleStage/{systemName}/Elements/{elementId}/CheckInOutJobs` | Async: check an element in or out for editing |

#### Channel endpoints

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/Channels/{systemName}` | List all campaigning channels configured for a FastStats system |
| `POST`   | `/Channels/{systemName}` | Update channel configuration (sync) *(OrbitAdmin only)* |
| `GET`    | `/Channels/{systemName}/{channelId}` | Get details of a specific channel |
| `GET`    | `/Channels/{systemName}/Broadcasters` | List broadcaster-type channel info |
| `GET`    | `/Channels/{systemName}/Facebook` | List Facebook channel info |
| `GET`    | `/Channels/{systemName}/Google` | List Google channel info |
| `GET`    | `/Channels/{systemName}/LinkedIn` | List LinkedIn channel info |
| `GET`    | `/Channels/{systemName}/PushNotifications` | List push notification channel info |
| `GET`    | `/Channels/{systemName}/{channelId}/AuthenticationDetails` | Get authentication details for a channel (requires `temporaryToken`) |
| `POST`   | `/Channels/{systemName}/{channelId}/AccountsJobs` | Async: retrieve available accounts for a channel (e.g. ad accounts) |
| `POST`   | `/Channels/{systemName}/{channelId}/AccountMessagesJobs` | Async: retrieve ad groups for a Google Ads account |
| `POST`   | `/Channels/{systemName}/{channelId}/MessagesJobs` | Async: retrieve available messages/templates for a channel |
| `POST`   | `/Channels/{systemName}/{channelId}/ListsJobs` | Async: retrieve available lists for a channel |
| `POST`   | `/Channels/{systemName}/{channelId}/TestLoginJobs` | Async: test authentication credentials for a channel |
| `POST`   | `/Channels/{systemName}/{channelId}/PreviewJobs` | Async: preview a message as it would be sent via this channel |
| `POST`   | `/Channels/{systemName}/ChannelsJobs` | Async: update channel configuration *(OrbitAdmin only)* |


### Sharing

A series of endpoints that allow for retreiving and modifying information about how resources are shared in Orbit.

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/Shares` | List all shares in the DataView *(OrbitAdmin only)* |
| `POST`   | `/Shares` | Create a new share |
| `PUT`    | `/Shares/MultipleShares` | Create multiple shares in a single request |
| `GET`    | `/Shares/{shareId}` | Get details of a specific share |
| `DELETE` | `/Shares/{shareId}` | Delete a share |
| `GET`    | `/Shares/{shareId}/Users` | List users associated with a share |
| `GET`    | `/Shares/{shareId}/Invitees` | List email address invitees associated with a share |
| `GET`    | `/Shares/{shareId}/Groups` | List groups associated with a share |
| `GET`    | `/Shares/{shareId}/Updates` | List all updates (changes in recipients) for a share |
| `POST`   | `/Shares/{shareId}/Updates` | Apply an update to a share (add/remove users, groups, or invitees)  |
| `GET`    | `/Shares/{shareId}/Updates/{shareUpdateId}` | Get details of a specific share update |
| `GET`    | `/Shares/{shareId}/Updates/{shareUpdateId}/AddedUsers` | List users added in a specific share update |
| `GET`    | `/Shares/{shareId}/Updates/{shareUpdateId}/RemovedUsers` | List users removed in a specific share update |


### FastStats System

A series of endpoints that allow for getting metadata about the tables and variables in each FastStats system contained within each Data View

| Method   | Path | Description |
|----------|------|-------------|
| `GET`    | `/FastStatsSystems` | List all FastStats systems available in the DataView |
| `GET`    | `/FastStatsSystems/{systemName}` | Get top-level details for a specific FastStats system |
| `GET`    | `/FastStatsSystems/{systemName}/Tables` | List all tables in the system |
| `GET`    | `/FastStatsSystems/{systemName}/Tables/{tableName}` | Get details for a specific table |
| `GET`    | `/FastStatsSystems/{systemName}/Variables` | List all variables in the system |
| `GET`    | `/FastStatsSystems/{systemName}/Variables/{variableName}` | Get details for a specific variable |
| `GET`    | `/FastStatsSystems/{systemName}/Variables/{variableName}/Codes` | List all category codes for a selector variable (GET variant) |
| `POST`   | `/FastStatsSystems/{systemName}/Variables/{variableName}/Codes` | List all category codes for a selector variable (POST variant, supports filters) |
| `POST`   | `/FastStatsSystems/{systemName}/Variables/TopVarCodes` | Get the top N codes for each of a set of specified variables |
| `POST`   | `/FastStatsSystems/{systemName}/Variables/SystemLookup` | Perform a system lookup across specified variables |
| `GET`    | `/FastStatsSystems/{systemName}/Folders` | Browse the root of the FastStats folder/variable tree |
| `GET`    | `/FastStatsSystems/{systemName}/Folders/{path}` | Browse the folder structure at a given path |
| `GET`    | `/FastStatsSystems/{systemName}/All` | Get all system items (variables, codes, tables, folders) in one call |
| `POST`   | `/FastStatsSystems/{systemName}/RefreshInformationSync` | Force a refresh of the cached FastStats system information *(OrbitAdmin only)* |
