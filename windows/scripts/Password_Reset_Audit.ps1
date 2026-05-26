param([int]$HoursBack = 24)
$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "password_reset_audit_$RunStamp.txt"
$Start = (Get-Date).AddHours(-$HoursBack)
$events = @()
$collectionError = $null
try {
    $events = @(Get-WinEvent -FilterHashtable @{LogName='Security';Id=4723,4724;StartTime=$Start} -ErrorAction Stop)
}
catch {
    $collectionError = $_.Exception.Message
}

"══════════════════════════════════════" | Set-Content $ReportFile
"PASSWORD CHANGE / RESET AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Events Found: $($events.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
if ($collectionError) {
  "[WARN] $collectionError" | Add-Content $ReportFile
}
elseif ($events.Count -eq 0) {
  "- No password change or reset events returned." | Add-Content $ReportFile
}
foreach ($e in $events) {
  $x=[xml]$e.ToXml(); $d=@{}
  foreach($i in $x.Event.EventData.Data){$d[$i.Name]=$i.'#text'}
  "- $($e.TimeCreated) | Event: $($e.Id) | Target: $($d['TargetUserName']) | PerformedBy: $($d['SubjectUserName'])" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
