param([int]$HoursBack = 24)
$ErrorActionPreference="Continue"
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\password_reset_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null
$Start=(Get-Date).AddHours(-$HoursBack)
$events=Get-WinEvent -FilterHashtable @{LogName='Security';Id=4723,4724;StartTime=$Start} -ErrorAction SilentlyContinue

"══════════════════════════════════════" | Set-Content $ReportFile
"PASSWORD CHANGE / RESET AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Events Found: $($events.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
foreach($e in $events){
  $x=[xml]$e.ToXml(); $d=@{}
  foreach($i in $x.Event.EventData.Data){$d[$i.Name]=$i.'#text'}
  "- $($e.TimeCreated) | Event: $($e.Id) | Target: $($d['TargetUserName']) | PerformedBy: $($d['SubjectUserName'])" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
