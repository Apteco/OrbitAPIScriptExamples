<#
.SYNOPSIS
    Authenticates against the Apteco Orbit API and outputs the access token.
 
.DESCRIPTION
    1. Calls POST /{dataViewName}/Sessions/SimpleLogin to obtain an access token.
    2. If the user has multi-factor authentication (MFA) turned on, SimpleLogin
       returns an MFA challenge instead. The script asks for the 6-digit code
       from the user's authenticator app and calls
       POST /{dataViewName}/Sessions/Mfa/Totp/Verify to obtain the access token.

    MFA codes change every 30 seconds and must be typed in by a person, so
    users with MFA turned on can't run this script unattended.

.PARAMETER BaseUrl
    The base URL of the Orbit API, for example https://example.com/OrbitAPI
 
.PARAMETER DataViewName
    The name of the DataView to act on, for example "holidays"
 
.PARAMETER Username
    The username to authenticate with, for example "myuser"

.PARAMETER Password
    The password to authenticate with. If omitted, PowerShell will prompt securely.

.PARAMETER MfaCode
    The current 6-digit code from the user's authenticator app. Only used if the
    user has MFA turned on. If omitted, PowerShell will prompt for it when needed.

.EXAMPLE
    .\Login.ps1 `
        -BaseUrl "https://example.com/OrbitAPI" `
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
    [string]$Password,

    [Parameter(Mandatory = $false)]
    [string]$MfaCode
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

# ---------------------------------------------------------------------------
# Complete the MFA challenge, if the user has MFA turned on
## ---------------------------------------------------------------------------
if ($loginResponse.state -eq 'SetupRequired') {
    Stop-WithError "User '$Username' must set up MFA before logging in. Log in to Orbit in a web browser to set it up, then run this script again."
}

if ($loginResponse.state -eq 'Challenge') {
    if ([string]::IsNullOrEmpty($MfaCode)) {
        $MfaCode = Read-Host "Enter the 6-digit code from your authenticator app"
    }

    $verifyUrl  = "$BaseUrl/$DataViewName/Sessions/Mfa/Totp/Verify"
    $verifyBody = @{
        mfaAccessToken = $loginResponse.mfaAccessToken
        code           = $MfaCode
    } | ConvertTo-Json

    Write-Host "Verifying MFA code against '$verifyUrl'..." -ForegroundColor Cyan

    try {
        $loginResponse = Invoke-RestMethod `
            -Uri         $verifyUrl `
            -Method      POST `
            -ContentType 'application/json' `
            -Body        $verifyBody `
            -ErrorAction Stop
    }
    catch {
        $statusCode = if ($_.Exception.Response) { $_.Exception.Response.StatusCode.value__ } else { $null }
        $errorBody  = if ($_.ErrorDetails) { $_.ErrorDetails.Message } else { $null }
        Stop-WithError "MFA verification failed (HTTP $statusCode). The code may be wrong or out of date. Response: $errorBody`nError: $_"
    }
}

# The session details include an accessToken property
$accessToken = $loginResponse.AccessToken
 
if ([string]::IsNullOrWhiteSpace($accessToken)) {
    Stop-WithError "Login succeeded but no AccessToken was returned. Full response: $($loginResponse | ConvertTo-Json -Depth 5)"
}

Write-Output $accessToken
Write-Host "Login successful. Access token obtained." -ForegroundColor Green