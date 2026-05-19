<#
.SYNOPSIS
    Posts a dashboard JSON file to the Apteco Orbit API.
 
.DESCRIPTION
    Uses a valid access token to POST a JSON file to /{dataViewName}/Dashboards.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER AccessToken
    A valid access token (gained from the Login.ps1 script) to authenticate with.

.PARAMETER SystemName
    The name of the system (within the Data View) to create the dashboard in.

.PARAMETER DashboardJsonPath
    The path to the JSON file to post to the Dashboards endpoint.
 
.EXAMPLE
    .\CreateDashboards.ps1 `
        -BaseUrl "https://example.com/holidays/OrbitAPI" `
        -DataViewName "holidays" `
        -AccessToken "your_access_token_here" `
        -SystemName "holidays" `
        -DashboardJsonPath ".\dashboard.json"
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
    [string]$SystemName,
 
    [Parameter(Mandatory = $true)]
    [string]$DashboardJsonPath
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
# Helper: ensure property exists on object with value
# ---------------------------------------------------------------------------
function UpsertPropertyValue {
    param(
        [psobject]$Obj,
        [string]$PropertyName,
        [string]$PropertyValue
    )

    if (-not (Get-Member -InputObject $Obj -Name $PropertyName -MemberType NoteProperty)) {
        $Obj | Add-Member -NotePropertyName $PropertyName -NotePropertyValue $PropertyValue
    } else {
        $Obj.$PropertyName = $PropertyValue
    }
}


# ---------------------------------------------------------------------------
# Validate the dashboard JSON file exists
# ---------------------------------------------------------------------------
if (-not (Test-Path -Path $DashboardJsonPath -PathType Leaf)) {
    Stop-WithError "Dashboard JSON file not found: $DashboardJsonPath"
}
 
# ---------------------------------------------------------------------------
# Post the dashboard JSON
# ---------------------------------------------------------------------------
$dashboardUrl  = "$BaseUrl/$DataViewName/Dashboards"
$dashboardJson = Get-Content -Path $DashboardJsonPath -Raw

$dashboardToCreate = ConvertFrom-Json -InputObject $dashboardJson
UpsertPropertyValue -Obj $dashboardToCreate -PropertyName 'systemName' -PropertyValue $SystemName
$dashboardJson = ConvertTo-Json -InputObject $dashboardToCreate -Depth 100

Write-Host "Posting dashboard JSON from '$DashboardJsonPath' to '$dashboardUrl'..." -ForegroundColor Cyan

$headers = @{
    Authorization = "Bearer $AccessToken"
}
 
try {
    $dashboardResponse = Invoke-RestMethod `
        -Uri         $dashboardUrl `
        -Method      POST `
        -ContentType 'application/json' `
        -Headers     $headers `
        -Body        $dashboardJson `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Dashboard POST failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}

Write-Host "Dashboard $($dashboardResponse.title) created successfully with $(@($dashboardResponse.workbookItems).Count) tabs!" -ForegroundColor Green
