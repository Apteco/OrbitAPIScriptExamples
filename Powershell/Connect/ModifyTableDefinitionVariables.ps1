<#
.SYNOPSIS
    Updates variable details across all user-defined table definitions based on a
    spec file.

.DESCRIPTION
    Reads a JSON spec file describing variable changes, fetches all user-defined
    table definitions from the Connect API, applies the specified variable changes
    to any matching variables, then posts an update for each table definition that
    was modified.

    The spec file must have the following structure:

    {
        "variable_mapping": [
            {
                "name": "<current variable name to match>",
                "new_definition": {
                    "id": "<new id>",
                    "name": "<new name>",
                    "type": "<new type>",
                    "properties": { ... }
                }
            }
        ]
    }

    The properties to be sent depend on the variable type. Use the GetTableDefintion
    script to see examples from your system.

    Only fields present (non-null) in new_definition are applied; omitted fields
    are left unchanged on the variable.

.PARAMETER BaseUrl
    The base URL of the Connect API, e.g. https://example.com/holidays/ConnectAPI

.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"

.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER SpecFile
    Path to the JSON file containing the variable mapping specification.

.EXAMPLE
    .\UpdateTableDefinitionVariables.ps1 `
        -BaseUrl "https://example.com/holidays/ConnectAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -SpecFile ".\table-definition-updates-spec.json"
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
    [string]$SpecFile
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
# Read and parse the spec file
# ---------------------------------------------------------------------------
if (-not (Test-Path $SpecFile)) {
    Stop-WithError "Spec file not found: $SpecFile"
}

$spec = Get-Content $SpecFile -Raw | ConvertFrom-Json
$variableMapping = $spec.variable_mapping

if (-not $variableMapping -or @($variableMapping).Count -eq 0) {
    Stop-WithError "No variable_mapping entries found in spec file."
}

$mappingByName = @{}
foreach ($entry in $variableMapping) {
    $mappingByName[$entry.name] = $entry.new_definition
}

Write-Host "Loaded $(@($variableMapping).Count) variable mapping(s) from spec file." -ForegroundColor Cyan

$headers = @{
    Authorization = "Bearer $AccessToken"
}

# ---------------------------------------------------------------------------
# Fetch all table definition summaries
# ---------------------------------------------------------------------------
$tableDefinitionsUrl = "$BaseUrl/$DataViewName/TableDefinitions"

Write-Host "Fetching all table definitions..." -ForegroundColor Cyan

$pageSize    = 100
$offset      = 0
$allSummaries = @()

do {
    try {
        $listResponse = Invoke-RestMethod `
            -Uri         "${tableDefinitionsUrl}?offset=$offset&count=$pageSize" `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "TableDefinitions GET failed (HTTP $statusCode). Response: $errorBody`nError: $_"
    }

    $page = @($listResponse.list)
    $allSummaries += $page
    $offset += $pageSize
}
while ($page.Count -gt 0)

Write-Host "Found $($allSummaries.Count) table definition(s)." -ForegroundColor Cyan

if ($allSummaries.Count -eq 0) {
    Write-Host "No table definitions found. Exiting." -ForegroundColor Yellow
    exit 0
}

# ---------------------------------------------------------------------------
# Fetch full details for each table definition
# ---------------------------------------------------------------------------
Write-Host "Fetching full details for each table definition..." -ForegroundColor Cyan

$allDetails = @()
foreach ($summary in $allSummaries) {
    try {
        $detail = Invoke-RestMethod `
            -Uri         "${tableDefinitionsUrl}/$($summary.id)" `
            -Method      GET `
            -ContentType 'application/json' `
            -Headers     $headers `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "TableDefinition GET failed for id $($summary.id) (HTTP $statusCode). Response: $errorBody`nError: $_"
    }
    $allDetails += $detail
}

# ---------------------------------------------------------------------------
# Apply variable changes and post an update for each modified definition
# ---------------------------------------------------------------------------
$updatedCount = 0

foreach ($detail in $allDetails) {
    $variables = if ($detail.schema -and $detail.schema.table) { $detail.schema.table.variables } else { $null }

    if (-not $variables -or @($variables).Count -eq 0) {
        continue
    }

    $modified = $false

    foreach ($variable in $variables) {
        if (-not $mappingByName.ContainsKey($variable.name)) {
            continue
        }

        $newDef = $mappingByName[$variable.name]

        Write-Host "  Applying mapping to variable '$($variable.name)' in '$($detail.title)' (id: $($detail.id))" -ForegroundColor Gray

        if ($null -ne $newDef.id)         { $variable.id         = $newDef.id }
        if ($null -ne $newDef.name)       { $variable.name       = $newDef.name }
        if ($null -ne $newDef.type)       { $variable.type       = $newDef.type }
        if ($null -ne $newDef.properties) { $variable.properties = $newDef.properties }

        $modified = $true
    }

    if (-not $modified) {
        continue
    }

    $updateBody = @{
        title  = $detail.title
        schema = $detail.schema
    }

    $referenceVariables = @($variables | Where-Object { $_.type -eq "Reference" })
    if ($referenceVariables.Count -eq 1) {
        $updateBody.hasReferenceVariable = $true
        $updateBody.referenceVariableId = $referenceVariables[0].id
    } else {
        $updateBody.hasReferenceVariable = $false
        $updateBody.referenceVariableId = $null
    }

    $updateJson = ConvertTo-Json -InputObject $updateBody -Depth 100

    Write-Host "Posting update for '$($detail.title)' (id: $($detail.id))..." -ForegroundColor Cyan

    try {
        $updateResponse = Invoke-RestMethod `
            -Uri         "${tableDefinitionsUrl}/$($detail.id)/Updates" `
            -Method      POST `
            -ContentType 'application/json' `
            -Headers     $headers `
            -Body        $updateJson `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "TableDefinition update POST failed for id $($detail.id) (HTTP $statusCode). Response: $errorBody`nError: $_"
    }

    Write-Host "  Updated successfully (new update id: $($updateResponse.updateId))." -ForegroundColor Green
    $updatedCount++
}

Write-Host ""
Write-Host "Done. $updatedCount table definition(s) updated." -ForegroundColor Green
