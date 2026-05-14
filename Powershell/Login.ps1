<#
.SYNOPSIS
    Authenticates against the Apteco Orbit API and outputs the access token.
 
.DESCRIPTION
    1. Calls POST /{dataViewName}/Sessions/SimpleLogin to obtain an access token.
 
.PARAMETER BaseUrl
    The base URL of the Orbit API, e.g. https://example.com/holidays/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, e.g. "holidays"
 
.PARAMETER Credential
    The credentials to authenticate with. If omitted, PowerShell will prompt securely.

.EXAMPLE
    .\Login.ps1 `
        -BaseUrl "https://www.example.com/OrbitAPI" `
        -DataViewName "holidays" `
        -Username "myuser"
#>
 
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,
 
    [Parameter(Mandatory = $true)]
    [string]$DataViewName,
 
    [Parameter(Mandatory = $true)]
    [string]$Username,
 
    [Parameter(Mandatory = $false)]
    [string]$Password
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
# Authenticate via SimpleLogin
# ---------------------------------------------------------------------------
$loginUrl = "$BaseUrl/$DataViewName/Sessions/SimpleLogin"

if ([string]::IsNullOrEmpty($Password)) {
    $securePassword = Read-Host -AsSecureString "Enter password"
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

$loginBody = "UserLogin=$([Uri]::EscapeDataString($Username))&Password=$([Uri]::EscapeDataString($Password))"
 
Write-Host "Authenticating as '$Username' against '$loginUrl'..." -ForegroundColor Cyan
 
try {
    $loginResponse = Invoke-RestMethod `
        -Uri         $loginUrl `
        -Method      POST `
        -ContentType 'application/x-www-form-urlencoded' `
        -Body        $loginBody `
        -ErrorAction Stop
}
catch {
    $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
    $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
    Stop-WithError "Login failed (HTTP $statusCode). Response: $errorBody`nError: $_"
}
 
# The API returns an object with an AccessToken property
$accessToken = $loginResponse.AccessToken
 
if ([string]::IsNullOrWhiteSpace($accessToken)) {
    Stop-WithError "Login succeeded but no AccessToken was returned. Full response: $($loginResponse | ConvertTo-Json -Depth 5)"
}

Write-Output $accessToken
Write-Host "Login successful. Access token obtained." -ForegroundColor Green