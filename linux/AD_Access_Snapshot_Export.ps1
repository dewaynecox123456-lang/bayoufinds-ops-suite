param(
    [Parameter(Mandatory=$true)]
    [string]$UserName
)

$ErrorActionPreference = "Stop"
$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN

$SnapshotId = "snapshot_{0}_{1}" -f $UserName, (Get-Date -Format "yyyyMMdd_HHmmss")

$OutputDir = ".\output"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$ReportFile = Join-Path $OutputDir ("{0}.txt" -f $SnapshotId)
$CsvFile = Join-Path $OutputDir ("{0}.csv" -f $SnapshotId)

Import-Module ActiveDirectory -ErrorAction Stop

$user = Get-ADUser -Identity $UserName -Properties DisplayName, DistinguishedName
$groups = Get-ADPrincipalGroupMembership -Identity $user | Sort-Object Name

# CSV export
$groups | Select-Object @{
    Name="UserName";Expression={$UserName}
}, @{
    Name="GroupName";Expression={$_.Name}
}, @{
    Name="GroupDN";Expression={$_.DistinguishedName}
}, @{
    Name="ExportedAt";Expression={$Timestamp}
}, @{
    Name="ExportedBy";Expression={$Operator}
}, @{
    Name="Domain";Expression={$Domain}
} | Export-Csv -Path $CsvFile -NoTypeInformation

# Report
"══════════════════════════════════════" | Set-Content $ReportFile
"ACCESS SNAPSHOT REPORT" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"AUDIT METADATA" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"- Snapshot ID: $SnapshotId" | Add-Content $ReportFile
"- Generated: $Timestamp" | Add-Content $ReportFile
"- Operator: $Operator" | Add-Content $ReportFile
"- Computer: $Computer" | Add-Content $ReportFile
"- Domain: $Domain" | Add-Content $ReportFile
"- Script Version: $ScriptVersion" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"USER" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"- SamAccountName: $($user.SamAccountName)" | Add-Content $ReportFile
"- DisplayName: $($user.DisplayName)" | Add-Content $ReportFile
"" | Add-Content $ReportFile

"══════════════════════════════════════" | Add-Content $ReportFile
"GROUP MEMBERSHIP" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
foreach ($g in $groups) {
    "- $($g.Name)" | Add-Content $ReportFile
}
"" | Add-Content $ReportFile

"CSV Snapshot: $CsvFile" | Add-Content $ReportFile
Write-Host "Snapshot complete: $ReportFile"
