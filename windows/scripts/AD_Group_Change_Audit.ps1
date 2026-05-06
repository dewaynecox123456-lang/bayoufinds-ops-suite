param([int]$HoursBack = 24)
$ErrorActionPreference="Continue"
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\ad_group_change_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null
$Start=(Get-Date).AddHours(-$HoursBack)
$ids=4728,4729,4732,4733,4756,4757
$events=Get-WinEvent -FilterHashtable @{LogName='Security';Id=$ids;StartTime=$Start} -ErrorAction SilentlyContinue

"══════════════════════════════════════" | Set-Content $ReportFile
"AD GROUP CHANGE AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Window: Last $HoursBack hour(s)" | Add-Content $ReportFile
"Group Change Events: $($events.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

foreach($e in $events){
  $x=[xml]$e.ToXml(); $d=@{}
  foreach($i in $x.Event.EventData.Data){$d[$i.Name]=$i.'#text'}
  "- $($e.TimeCreated) | Event: $($e.Id) | Target: $($d['TargetUserName']) | Group: $($d['TargetSid']) | ChangedBy: $($d['SubjectUserName'])" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
