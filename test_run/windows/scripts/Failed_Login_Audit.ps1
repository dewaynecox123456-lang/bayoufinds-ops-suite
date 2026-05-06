param(
    [int]$HoursBack = 24
)

$ErrorActionPreference = "Continue"
$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$ReportFile = Join-Path $OutputDir "failed_login_audit_$RunStamp.txt"

$StartTime = (Get-Date).AddHours(-$HoursBack)

$events = Get-WinEvent -FilterHashtable @{
    LogName='Security'
    Id=4625
    StartTime=$StartTime
} -ErrorAction SilentlyContinue

$records = foreach ($e in $events) {
    $xml = [xml]$e.ToXml()
    $data = @{}
    foreach ($d in $xml.Event.EventData.Data) {
        $data[$d.Name] = $d.'#text'
    }

    [PSCustomObject]@{
        TimeCreated   = $e.TimeCreated
        TargetUser    = $data['TargetUserName']
        Domain        = $data['TargetDomainName']
        SourceAddress = $data['IpAddress']
        Workstation   = $data['WorkstationName']
        LogonType     = $data['LogonType']
        Status        = $data['Status']
        SubStatus     = $data['SubStatus']
    }
}

$userTop = $records | Group-Object TargetUser | Sort-Object Count -Descending | Select-Object -First 10
$sourceTop = $records | Group-Object SourceAddress | Sort-Object Count -Descending | Select-Object -First 10

"══════════════════════════════════════" | Set-Content $ReportFile
"FAILED LOGIN / BRUTE FORCE AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"Generated: $Timestamp" | Add-Content $ReportFile
"Operator: $Operator" | Add-Content $ReportFile
"Computer: $Computer" | Add-Content $ReportFile
"Domain: $Domain" | Add-Content $ReportFile
"Script Version: $ScriptVersion" | Add-Content $ReportFile
"Window: Last $HoursBack hour(s)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"SUMMARY" | Add-Content $ReportFile
"-------" | Add-Content $ReportFile
"Failed Logons Found: $($records.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"TOP TARGET USERS" | Add-Content $ReportFile
"----------------" | Add-Content $ReportFile
if ($userTop) {
    foreach ($u in $userTop) {
        "- $($u.Name): $($u.Count)" | Add-Content $ReportFile
    }
} else {
    "- None detected" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"TOP SOURCE ADDRESSES" | Add-Content $ReportFile
"--------------------" | Add-Content $ReportFile
if ($sourceTop) {
    foreach ($s in $sourceTop) {
        "- $($s.Name): $($s.Count)" | Add-Content $ReportFile
    }
} else {
    "- None detected" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"INSIGHT" | Add-Content $ReportFile
"-------" | Add-Content $ReportFile
if ($records.Count -ge 50) {
    "- High failed logon volume detected. Review top users and source addresses for brute-force or stale credential activity." | Add-Content $ReportFile
} elseif ($records.Count -gt 0) {
    "- Failed logons detected. Review for stale passwords, mapped drives, services, scheduled tasks, or malicious attempts." | Add-Content $ReportFile
} else {
    "- No failed logons detected in selected window." | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"RECENT EVENTS" | Add-Content $ReportFile
"-------------" | Add-Content $ReportFile
foreach ($r in ($records | Select-Object -First 25)) {
    "- $($r.TimeCreated) | User: $($r.TargetUser) | Source: $($r.SourceAddress) | Workstation: $($r.Workstation) | LogonType: $($r.LogonType) | Status: $($r.Status)" | Add-Content $ReportFile
}

"" | Add-Content $ReportFile
"──────────────────────────────────────" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile

Write-Host "Report complete: $ReportFile"
