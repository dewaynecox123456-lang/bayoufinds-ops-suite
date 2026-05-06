[CmdletBinding()]
param(
    [string]$SearchBase = "",
    [string]$OutDir = ".\output",
    [switch]$MockMode
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Ensure-Directory -Path $OutDir
$csvPath = Join-Path $OutDir "AD_User_Audit_Report_$timestamp.csv"

if ($MockMode) {
    Write-Host "[INFO] Running in MockMode (no AD required)" -ForegroundColor Cyan

    $users = @(
        [PSCustomObject]@{
            DisplayName            = "Alice Johnson"
            SamAccountName         = "ajohnson"
            UserPrincipalName      = "ajohnson@example.local"
            Enabled                = $true
            GivenName              = "Alice"
            Surname                = "Johnson"
            Department             = "Finance"
            Title                  = "Analyst"
            Mail                   = "ajohnson@example.local"
            LastLogonDate          = (Get-Date).AddDays(-1)
            PasswordLastSet        = (Get-Date).AddDays(-30)
            PasswordNeverExpires   = $false
            CannotChangePassword   = $false
            LockedOut              = $false
            Created                = (Get-Date).AddYears(-2)
            Modified               = (Get-Date).AddDays(-7)
        },
        [PSCustomObject]@{
            DisplayName            = "Bob Smith"
            SamAccountName         = "bsmith"
            UserPrincipalName      = "bsmith@example.local"
            Enabled                = $false
            GivenName              = "Bob"
            Surname                = "Smith"
            Department             = "IT"
            Title                  = "Support Engineer"
            Mail                   = "bsmith@example.local"
            LastLogonDate          = (Get-Date).AddDays(-14)
            PasswordLastSet        = (Get-Date).AddDays(-90)
            PasswordNeverExpires   = $true
            CannotChangePassword   = $false
            LockedOut              = $true
            Created                = (Get-Date).AddYears(-3)
            Modified               = (Get-Date).AddDays(-10)
        }
    )
}
else {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Host "ERROR: ActiveDirectory module not found. Run this on a domain-joined machine with RSAT/AD tools installed, or use -MockMode." -ForegroundColor Red
        exit 1
    }

    $props = @(
        "DisplayName",
        "SamAccountName",
        "UserPrincipalName",
        "Enabled",
        "GivenName",
        "Surname",
        "Department",
        "Title",
        "Mail",
        "LastLogonDate",
        "PasswordLastSet",
        "PasswordNeverExpires",
        "CannotChangePassword",
        "LockedOut",
        "Created",
        "Modified"
    )

    $adParams = @{
        Filter     = '*'
        Properties = $props
    }

    if ($SearchBase -and $SearchBase.Trim() -ne "") {
        $adParams.SearchBase = $SearchBase
    }

    $users = Get-ADUser @adParams | Select-Object `
        DisplayName,
        SamAccountName,
        UserPrincipalName,
        Enabled,
        GivenName,
        Surname,
        Department,
        Title,
        Mail,
        LastLogonDate,
        PasswordLastSet,
        PasswordNeverExpires,
        CannotChangePassword,
        LockedOut,
        Created,
        Modified
}

$users | Sort-Object DisplayName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$totalUsers = $users.Count
$enabledUsers = ($users | Where-Object { $_.Enabled -eq $true }).Count
$disabledUsers = ($users | Where-Object { $_.Enabled -eq $false }).Count
$lockedUsers = ($users | Where-Object { $_.LockedOut -eq $true }).Count
$pwdNeverExpires = ($users | Where-Object { $_.PasswordNeverExpires -eq $true }).Count

Write-Host ""
Write-Host "AD User Audit Report complete." -ForegroundColor Green
Write-Host "CSV: $csvPath"
Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Total Users:              $totalUsers"
Write-Host "Enabled Users:            $enabledUsers"
Write-Host "Disabled Users:           $disabledUsers"
Write-Host "Locked Out Users:         $lockedUsers"
Write-Host "Password Never Expires:   $pwdNeverExpires"
Write-Host ""
