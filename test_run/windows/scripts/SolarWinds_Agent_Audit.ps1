param([string]$OU = "")
$ErrorActionPreference="Continue"
Import-Module ActiveDirectory -ErrorAction Stop
$RunStamp=Get-Date -Format "yyyyMMdd_HHmmss"
$ReportFile=".\output\solarwinds_agent_audit_$RunStamp.txt"
New-Item -ItemType Directory -Force -Path ".\output" | Out-Null

if($OU){$servers=Get-ADComputer -SearchBase $OU -Filter * -Properties OperatingSystem}
else{$servers=Get-ADComputer -Filter {OperatingSystem -like "*Server*"} -Properties OperatingSystem}

$installed=@(); $missing=@()
foreach($s in $servers){
  try{
    $svc=Get-Service -ComputerName $s.Name -Name "SolarWinds*" -ErrorAction Stop
    if($svc){$installed+=$s.Name}else{$missing+=$s.Name}
  }catch{$missing+=$s.Name}
}

"══════════════════════════════════════" | Set-Content $ReportFile
"SOLARWINDS AGENT AUDIT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Servers Checked: $($servers.Count)" | Add-Content $ReportFile
"With SolarWinds: $($installed.Count)" | Add-Content $ReportFile
"Missing SolarWinds: $($missing.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile
"MISSING SOLARWINDS AGENT" | Add-Content $ReportFile
"------------------------" | Add-Content $ReportFile
$missing | ForEach-Object { "- $_" | Add-Content $ReportFile }
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
