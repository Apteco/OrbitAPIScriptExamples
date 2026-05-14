<#
.SYNOPSIS
    Gets a specific table definition in a DataView.

.DESCRIPTION
    Uses a valid access token to GET a specific table definition from /{dataViewName}/TableDefinitions/{tableDefinitionId}.
    Requires the OrbitAdmin role.

.PARAMETER BaseUrl
    The base URL of the Connect API, e.g. https://example.com/holidays/ConnectAPI

.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"

.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER TableDefinitionId
    The ID of the table definition to retrieve.

.EXAMPLE
    .\GetTableDefinition.ps1 `
        -BaseUrl "https://example.com/holidays/ConnectAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -TableDefinitionId 1234
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$DataViewName,

    [Parameter(Mandatory = $true)]
    [string]$AccessToken,

    [Parameter(Mandatory = $true)]
    [int]$TableDefinitionId
)

# ---------------------------------------------------------------------------
# Helper: exit with a clear error message
# ---------------------------------------------------------------------------
function Stop-WithError {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

# ---------------------------------------------------------------------------
# Get the table definition
# ---------------------------------------------------------------------------
$tableDefinitionUrl = "$BaseUrl/$DataViewName/TableDefinitions/$TableDefinitionId"

$headers = @{
    Authorization = "Bearer $AccessToken"
}

Write-Host "Getting table definition $TableDefinitionId..." -ForegroundColor Cyan

try {
    $tableDefinitionResponse = Invoke-RestMethod `
        -Uri         $tableDefinitionUrl `
        -Method      GET `
        -ContentType 'application/json' `
        -Headers     $headers `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "TableDefinition $TableDefinitionId GET failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

$tableDefinitionResponse | ConvertTo-Json -Depth 100

Write-Host "Got table definition $($tableDefinitionResponse.id): $($tableDefinitionResponse.title)" -ForegroundColor Green

