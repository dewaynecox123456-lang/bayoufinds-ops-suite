$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot

$ReportFile = Join-Path $OutputDir ("ad_description_keyword_audit_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

if (-not (Import-BayouFindsActiveDirectoryModule)) {
    "AD DESCRIPTION KEYWORD AUDIT" | Set-Content $ReportFile
    "" | Add-Content $ReportFile
    "[ERROR] ActiveDirectory module is unavailable. Run this on a domain-joined system with RSAT/AD tools installed." | Add-Content $ReportFile
    Write-Host "Report complete with errors: $ReportFile" -ForegroundColor Yellow
    exit 1
}

$keywords = @(
    "hacked",
    "pwned",
    "compromised",
    "test",
    "terminated",
    "contractor",
    "service",
    "do not delete"
)

$users = Get-ADUser -Filter * -Properties Description, LastLogonDate, Enabled, DisplayName

$results = @()

foreach ($user in $users) {
    if ($user.Description) {
        foreach ($k in $keywords) {
            if ($user.Description -match $k) {
                $results += [PSCustomObject]@{
                    SamAccountName = $user.SamAccountName
                    DisplayName    = $user.DisplayName
                    Enabled        = $user.Enabled
                    LastLogonDate  = $user.LastLogonDate
                    Keyword        = $k
                    Description    = $user.Description
                }
            }
        }
    }
}

"══════════════════════════════════════" | Set-Content $ReportFile
"AD DESCRIPTION KEYWORD AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"Generated: $Timestamp" | Add-Content $ReportFile
"Operator: $Operator" | Add-Content $ReportFile
"Computer: $Computer" | Add-Content $ReportFile
"Domain: $Domain" | Add-Content $ReportFile
"Script Version: $ScriptVersion" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"Matches Found: $($results.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

foreach ($r in $results) {
    "- $($r.SamAccountName) | Enabled: $($r.Enabled) | LastLogon: $($r.LastLogonDate) | Keyword: $($r.Keyword)" | Add-Content $ReportFile
    "  Description: $($r.Description)" | Add-Content $ReportFile
    "" | Add-Content $ReportFile
}

"──────────────────────────────────────" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile

Write-Host "Report complete: $ReportFile"
