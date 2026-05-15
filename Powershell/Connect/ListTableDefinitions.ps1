<#
.SYNOPSIS
    Lists all user-defined table definitions in a DataView.

.DESCRIPTION
    Uses a valid access token to GET the list of user-defined table definitions
    from /{dataViewName}/TableDefinitions.
    Requires the OrbitAdmin role.

.PARAMETER BaseUrl
    The base URL of the Connect API, e.g. https://example.com/holidays/ConnectAPI

.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"

.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.EXAMPLE
    .\ListTableDefinitions.ps1 `
        -BaseUrl "https://example.com/holidays/ConnectAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$DataViewName,

    [Parameter(Mandatory = $true)]
    [string]$AccessToken
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
# Get the list of table definitions (paged)
# ---------------------------------------------------------------------------
$tableDefinitionsUrl = "$BaseUrl/$DataViewName/TableDefinitions"

$headers = @{
    Authorization = "Bearer $AccessToken"
}

Write-Host "Getting table definitions..." -ForegroundColor Cyan

$pageSize  = 100
$offset    = 0
$totalCount = 0

do {
    $uri = "${tableDefinitionsUrl}?offset=$offset&count=$pageSize"

    try {
        $response = Invoke-RestMethod `
            -Uri         $uri `
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

    $page = @($response.list)
    foreach ($item in $page) {
        Write-Output "$($item.id): $($item.title)"
    }

    $offset    += $pageSize
    $totalCount += $page.Count
}
while ($page.Count -gt 0)

Write-Host "Got $totalCount table definitions" -ForegroundColor Green
