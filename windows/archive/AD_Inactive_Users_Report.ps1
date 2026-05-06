[CmdletBinding()]
param(
    [int]$DaysInactive = 90,
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
$csvPath = Join-Path $OutDir "AD_Inactive_Users_$timestamp.csv"

$cutoffDate = (Get-Date).AddDays(-$DaysInactive)

if ($MockMode) {
    Write-Host "[INFO] Running in MockMode" -ForegroundColor Cyan

    $users = @(
        [PSCustomObject]@{
            DisplayName       = "Alice Johnson"
            SamAccountName    = "ajohnson"
            UserPrincipalName = "ajohnson@example.local"
            Enabled           = $true
            Department        = "Finance"
            Title             = "Analyst"
            LastLogonDate     = (Get-Date).AddDays(-120)
        },
        [PSCustomObject]@{
            DisplayName       = "Bob Smith"
            SamAccountName    = "bsmith"
            UserPrincipalName = "bsmith@example.local"
            Enabled           = $true
            Department        = "IT"
            Title             = "Engineer"
            LastLogonDate     = (Get-Date).AddDays(-200)
        }
    )
}
else {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Host "ERROR: ActiveDirectory module not found. Use -MockMode or run on domain machine." -ForegroundColor Red
        exit 1
    }

    $props = @(
        "DisplayName",
        "SamAccountName",
        "UserPrincipalName",
        "Enabled",
        "Department",
        "Title",
        "LastLogonDate"
    )

    $adParams = @{
        Filter     = '*'
        Properties = $props
    }

    if ($SearchBase -and $SearchBase.Trim() -ne "") {
        $adParams.SearchBase = $SearchBase
    }

    $rawUsers = Get-ADUser @adParams

    $users = $rawUsers | Where-Object {
        $_.Enabled -eq $true -and
        $_.LastLogonDate -and
        $_.LastLogonDate -lt $cutoffDate
    } | Select-Object `
        DisplayName,
        SamAccountName,
        UserPrincipalName,
        Enabled,
        Department,
        Title,
        LastLogonDate
}

$users | Sort-Object LastLogonDate | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$total = $users.Count

Write-Host ""
Write-Host "Inactive Users Audit complete." -ForegroundColor Green
Write-Host "CSV: $csvPath"
Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Days Inactive Threshold: $DaysInactive"
Write-Host "Total Inactive Users:    $total"
Write-Host ""
