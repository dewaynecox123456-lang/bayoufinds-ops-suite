$ErrorActionPreference = "Stop"

$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$ReportFile = Join-Path $OutputDir ("ad_description_keyword_audit_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

Import-Module ActiveDirectory -ErrorAction Stop

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
