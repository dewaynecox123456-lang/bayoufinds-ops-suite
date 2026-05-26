$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot
$ReportFile = Join-Path $OutputDir "lockout_hunter_4740_$RunStamp.txt"

Write-Host "LOCKOUT HUNTER (Event 4740)"

$events = @()
$collectionError = $null
try {
    $events = @(Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4740} -MaxEvents 10 -ErrorAction Stop)
}
catch {
    $collectionError = $_.Exception.Message
}

$results = @()
foreach ($e in $events) {
    $xml = [xml]$e.ToXml()
    $user = $xml.Event.EventData.Data | Where-Object {$_.Name -eq "TargetUserName"} | Select-Object -ExpandProperty '#text'
    $caller = $xml.Event.EventData.Data | Where-Object {$_.Name -eq "CallerComputerName"} | Select-Object -ExpandProperty '#text'

    $results += [PSCustomObject]@{
        Time = $e.TimeCreated
        User = $user
        Caller = $caller
    }
}

"══════════════════════════════════════" | Set-Content $ReportFile
"LOCKOUT HUNTER (EVENT 4740)" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"Events Found: $($results.Count)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

if ($collectionError) {
    "[WARN] $collectionError" | Add-Content $ReportFile
}
elseif ($results.Count -eq 0) {
    "- No lockout events returned from the Security log." | Add-Content $ReportFile
}
else {
    foreach ($result in $results) {
        "- $($result.Time) | User: $($result.User) | Caller: $($result.Caller)" | Add-Content $ReportFile
    }
}

"" | Add-Content $ReportFile
"© BayouFinds.com - All rights reserved." | Add-Content $ReportFile
"support@bayoufinds.com | https://bayoufinds.com" | Add-Content $ReportFile

$results | Format-Table -AutoSize
Write-Host "Report complete: $ReportFile"
