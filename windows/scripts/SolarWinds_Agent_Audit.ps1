param([string]$OU = "")
$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "solarwinds_agent_audit_$RunStamp.txt"
$servers = @()
$collectionError = $null

if (Import-BayouFindsActiveDirectoryModule) {
  try {
    if ($OU) {
      $servers = @(Get-ADComputer -SearchBase $OU -Filter * -Properties OperatingSystem -ErrorAction Stop)
    }
    else {
      $servers = @(Get-ADComputer -Filter { OperatingSystem -like "*Server*" } -Properties OperatingSystem -ErrorAction Stop)
    }
  }
  catch {
    $collectionError = $_.Exception.Message
  }
}
else {
  $collectionError = "ActiveDirectory module is unavailable."
}

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
if ($collectionError) {
  "[WARN] $collectionError" | Add-Content $ReportFile
  "" | Add-Content $ReportFile
}
"MISSING SOLARWINDS AGENT" | Add-Content $ReportFile
"------------------------" | Add-Content $ReportFile
if ($missing.Count -eq 0 -and -not $collectionError) {
  "- No missing agents detected." | Add-Content $ReportFile
}
else {
  $missing | ForEach-Object { "- $_" | Add-Content $ReportFile }
}
"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile
Write-Host "Report complete: $ReportFile"
