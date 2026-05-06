[CmdletBinding()]
param(
    [string]$SearchBase = "",
    [string]$OutDir = ".\output",
    [string]$Attribute = "extensionAttribute10",
    [string]$TermDate = "",
    [switch]$ContainsMatch,
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
$csvPath = Join-Path $OutDir "AD_Termination_Date_Audit_$timestamp.csv"

if (-not $TermDate) {
    $TermDate = Read-Host "Enter termination date (example: 2026-04-22)"
}

if ($MockMode) {
    Write-Host "[INFO] Running in MockMode" -ForegroundColor Cyan

    $users = @(
        [PSCustomObject]@{
            DisplayName = "Alice Johnson"
            SamAccountName = "ajohnson"
            UserPrincipalName = "ajohnson@example.local"
            Enabled = $false
            Department = "Finance"
            Title = "Analyst"
            Mail = "ajohnson@example.local"
            LastLogonDate = (Get-Date).AddDays(-30)
            TerminationValue = "2026-04-22"
        },
        [PSCustomObject]@{
            DisplayName = "Bob Smith"
            SamAccountName = "bsmith"
            UserPrincipalName = "bsmith@example.local"
            Enabled = $true
            Department = "IT"
            Title = "Engineer"
            Mail = "bsmith@example.local"
            LastLogonDate = (Get-Date).AddDays(-2)
            TerminationValue = "2026-04-22"
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
        "Mail",
        "LastLogonDate",
        $Attribute
    )

    $adParams = @{
        Filter = '*'
        Properties = $props
    }

    if ($SearchBase -and $SearchBase.Trim() -ne "") {
        $adParams.SearchBase = $SearchBase
    }

    $rawUsers = Get-ADUser @adParams

    if ($ContainsMatch) {
        $filtered = $rawUsers | Where-Object { $_.$Attribute -like "*$TermDate*" }
    } else {
        $filtered = $rawUsers | Where-Object { $_.$Attribute -eq $TermDate }
    }

    $users = $filtered | Select-Object `
        DisplayName,
        SamAccountName,
        UserPrincipalName,
        Enabled,
        Department,
        Title,
        Mail,
        LastLogonDate,
        @{Name="TerminationValue";Expression={ $_.$Attribute }}
}

$users | Sort-Object DisplayName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$total = $users.Count
$enabled = ($users | Where-Object { $_.Enabled -eq $true }).Count
$disabled = ($users | Where-Object { $_.Enabled -eq $false }).Count

Write-Host ""
Write-Host "Termination Date Audit complete." -ForegroundColor Green
Write-Host "CSV: $csvPath"
Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Total Matches:        $total"
Write-Host "Enabled Accounts:     $enabled"
Write-Host "Disabled Accounts:    $disabled"
Write-Host ""
