param([int]$HoursBack = 24)
$ErrorActionPreference="Continue"
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\logon_success_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null
$Start=(Get-Date).AddHours(-$HoursBack)

$events=Get-WinEvent -FilterHashtable @{LogName='Security';Id=4624;StartTime=$Start} -ErrorAction SilentlyContinue
"══════════════════════════════════════" | Set-Content $ReportFile
"LOGON SUCCESS AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Window: Last $HoursBack hour(s)" | Add-Content $ReportFile
"Total Successful Logons: $($events.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

foreach($e in ($events | Select-Object -First 50)){
  $x=[xml]$e.ToXml(); $d=@{}
  foreach($i in $x.Event.EventData.Data){$d[$i.Name]=$i.'#text'}
  "- $($e.TimeCreated) | User: $($d['TargetUserName']) | IP: $($d['IpAddress']) | Workstation: $($d['WorkstationName']) | LogonType: $($d['LogonType'])" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
