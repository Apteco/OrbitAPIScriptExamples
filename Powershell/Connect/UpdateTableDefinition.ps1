<#
.SYNOPSIS
    Posts a JSON file to update an existing table definition in the Apteco Connect API.
 
.DESCRIPTION
    Uses a valid access token to POST a JSON file to /{dataViewName}/TableDefinitions/{tableDefinitionId}/Updates.
 
.PARAMETER BaseUrl
    The base URL of the Connect API, e.g. https://example.com/Holidays/ConnectAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.
 
.PARAMETER TableDefinitionId
    The ID of the table definition to update.
 
.PARAMETER TableDefinitionJsonPath
    The path to the JSON file to post to the TableDefinitions endpoint.

.EXAMPLE
    .\UpdateTableDefinition.ps1 `
        -BaseUrl "https://example.com/Holidays/ConnectAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -TableDefinitionId 12345 `
        -TableDefinitionJsonPath ".\tableDefinition.json"
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
    [int]$TableDefinitionId,
 
    [Parameter(Mandatory = $true)]
    [string]$TableDefinitionJsonPath
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
# Validate the table definition JSON file exists
# ---------------------------------------------------------------------------
if (-not (Test-Path -Path $TableDefinitionJsonPath -PathType Leaf)) {
    Stop-WithError "Table definition JSON file not found: $TableDefinitionJsonPath"
}
 
# ---------------------------------------------------------------------------
# Post the table definition JSON
# ---------------------------------------------------------------------------
$tableDefinitionUrl  = "$BaseUrl/$DataViewName/TableDefinitions/$TableDefinitionId/Updates"
$tableDefinitionJson = Get-Content -Path $TableDefinitionJsonPath -Raw
 
Write-Host "Posting table definition JSON from '$TableDefinitionJsonPath' to '$tableDefinitionUrl'..." -ForegroundColor Cyan
 
$headers = @{
    Authorization = "Bearer $AccessToken"
}
 
try {
    $tableDefinitionResponse = Invoke-RestMethod `
        -Uri         $tableDefinitionUrl `
        -Method      POST `
        -ContentType 'application/json' `
        -Headers     $headers `
        -Body        $tableDefinitionJson `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "TableDefinitions POST failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

Write-Host "Table definition $($tableDefinitionResponse.title) (Update ID: $($tableDefinitionResponse.updateId)) updated successfully!" -ForegroundColor Green
