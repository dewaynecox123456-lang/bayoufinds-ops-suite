param([int]$HoursBack = 24)
$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "logon_success_audit_$RunStamp.txt"
$Start = (Get-Date).AddHours(-$HoursBack)

$events = @()
$collectionError = $null
try {
    $events = @(Get-WinEvent -FilterHashtable @{LogName='Security';Id=4624;StartTime=$Start} -ErrorAction Stop)
}
catch {
    $collectionError = $_.Exception.Message
}
"══════════════════════════════════════" | Set-Content $ReportFile
"LOGON SUCCESS AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Window: Last $HoursBack hour(s)" | Add-Content $ReportFile
"Total Successful Logons: $($events.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

if ($collectionError) {
  "[WARN] $collectionError" | Add-Content $ReportFile
}
elseif ($events.Count -eq 0) {
  "- No successful logon events returned." | Add-Content $ReportFile
}
foreach ($e in ($events | Select-Object -First 50)) {
  $x=[xml]$e.ToXml(); $d=@{}
  foreach($i in $x.Event.EventData.Data){$d[$i.Name]=$i.'#text'}
  "- $($e.TimeCreated) | User: $($d['TargetUserName']) | IP: $($d['IpAddress']) | Workstation: $($d['WorkstationName']) | LogonType: $($d['LogonType'])" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
