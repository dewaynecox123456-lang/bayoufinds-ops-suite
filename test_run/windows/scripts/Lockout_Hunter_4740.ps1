Write-Host "LOCKOUT HUNTER (Event 4740)"
$events = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4740} -MaxEvents 10 -ErrorAction SilentlyContinue

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

$results | Format-Table -AutoSize
