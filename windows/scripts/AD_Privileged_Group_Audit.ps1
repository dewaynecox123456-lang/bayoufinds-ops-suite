[CmdletBinding()]
param(
    [string]$SearchBase = "",
    [string]$OutDir = ".\output",
    [switch]$MockMode,
    [string[]]$PrivilegedGroups = @(
        "Domain Admins",
        "Enterprise Admins",
        "Schema Admins",
        "Administrators",
        "Account Operators",
        "Server Operators",
        "Backup Operators",
        "Print Operators"
    )
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function New-Row {
    param(
        [string]$GroupName,
        [string]$GroupSamAccountName,
        [string]$MemberName,
        [string]$MemberSamAccountName,
        [string]$MemberObjectClass,
        [string]$MemberDistinguishedName,
        [string]$MemberEnabled,
        [string]$Source
    )

    [PSCustomObject]@{
        GroupName                = $GroupName
        GroupSamAccountName      = $GroupSamAccountName
        MemberName               = $MemberName
        MemberSamAccountName     = $MemberSamAccountName
        MemberObjectClass        = $MemberObjectClass
        MemberDistinguishedName  = $MemberDistinguishedName
        MemberEnabled            = $MemberEnabled
        Source                   = $Source
    }
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Ensure-Directory -Path $OutDir

$csvPath = Join-Path $OutDir "AD_Privileged_Group_Audit_$timestamp.csv"

if ($MockMode) {
    Write-Host "[INFO] Running in MockMode (no AD required)" -ForegroundColor Cyan

    $rows = @(
        (New-Row -GroupName "Domain Admins" -GroupSamAccountName "Domain Admins" -MemberName "Alice Admin" -MemberSamAccountName "aadmin" -MemberObjectClass "user" -MemberDistinguishedName "CN=Alice Admin,OU=Admins,DC=example,DC=local" -MemberEnabled "True" -Source "MockMode"),
        (New-Row -GroupName "Domain Admins" -GroupSamAccountName "Domain Admins" -MemberName "IT Admin Team" -MemberSamAccountName "IT_Admin_Team" -MemberObjectClass "group" -MemberDistinguishedName "CN=IT Admin Team,OU=Groups,DC=example,DC=local" -MemberEnabled "" -Source "MockMode"),
        (New-Row -GroupName "Administrators" -GroupSamAccountName "Administrators" -MemberName "Bob Ops" -MemberSamAccountName "bops" -MemberObjectClass "user" -MemberDistinguishedName "CN=Bob Ops,OU=IT,DC=example,DC=local" -MemberEnabled "True" -Source "MockMode"),
        (New-Row -GroupName "Backup Operators" -GroupSamAccountName "Backup Operators" -MemberName "SvcBackup" -MemberSamAccountName "svc_backup" -MemberObjectClass "user" -MemberDistinguishedName "CN=SvcBackup,OU=Service Accounts,DC=example,DC=local" -MemberEnabled "True" -Source "MockMode"),
        (New-Row -GroupName "Schema Admins" -GroupSamAccountName "Schema Admins" -MemberName "<NO MEMBERS>" -MemberSamAccountName "" -MemberObjectClass "" -MemberDistinguishedName "" -MemberEnabled "" -Source "MockMode")
    )
}
else {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Host "ERROR: ActiveDirectory module not found. Run this on a domain-joined machine with RSAT/AD tools installed, or use -MockMode." -ForegroundColor Red
        exit 1
    }

    $rows = @()

    foreach ($groupName in $PrivilegedGroups) {
        try {
            $groupParams = @{
                Identity   = $groupName
                Properties = @("SamAccountName", "Name", "DistinguishedName")
            }

            if ($SearchBase -and $SearchBase.Trim() -ne "") {
                # Identity lookups ignore SearchBase, so we only use SearchBase if we need fallback search.
                $null = $SearchBase
            }

            $group = Get-ADGroup @groupParams

            $members = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive -ErrorAction Stop

            if (-not $members -or $members.Count -eq 0) {
                $rows += New-Row `
                    -GroupName $group.Name `
                    -GroupSamAccountName $group.SamAccountName `
                    -MemberName "<NO MEMBERS>" `
                    -MemberSamAccountName "" `
                    -MemberObjectClass "" `
                    -MemberDistinguishedName "" `
                    -MemberEnabled "" `
                    -Source "AD"
                continue
            }

            foreach ($member in $members) {
                $enabledValue = ""

                if ($member.objectClass -eq "user") {
                    try {
                        $user = Get-ADUser -Identity $member.DistinguishedName -Properties Enabled -ErrorAction Stop
                        $enabledValue = [string]$user.Enabled
                    }
                    catch {
                        $enabledValue = "UNKNOWN"
                    }
                }

                $rows += New-Row `
                    -GroupName $group.Name `
                    -GroupSamAccountName $group.SamAccountName `
                    -MemberName $member.Name `
                    -MemberSamAccountName $member.SamAccountName `
                    -MemberObjectClass $member.objectClass `
                    -MemberDistinguishedName $member.DistinguishedName `
                    -MemberEnabled $enabledValue `
                    -Source "AD"
            }
        }
        catch {
            $rows += New-Row `
                -GroupName $groupName `
                -GroupSamAccountName "" `
                -MemberName "<ERROR>" `
                -MemberSamAccountName "" `
                -MemberObjectClass "" `
                -MemberDistinguishedName $_.Exception.Message `
                -MemberEnabled "" `
                -Source "AD"
        }
    }
}

$rows | Sort-Object GroupName, MemberName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$totalRows = $rows.Count
$uniqueGroups = ($rows | Select-Object -ExpandProperty GroupName -Unique).Count
$userMembers = ($rows | Where-Object { $_.MemberObjectClass -eq "user" }).Count
$groupMembers = ($rows | Where-Object { $_.MemberObjectClass -eq "group" }).Count
$errorRows = ($rows | Where-Object { $_.MemberName -eq "<ERROR>" }).Count
$emptyGroups = ($rows | Where-Object { $_.MemberName -eq "<NO MEMBERS>" }).Count

Write-Host ""
Write-Host "AD Privileged Group Audit complete." -ForegroundColor Green
Write-Host "CSV: $csvPath"
Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Rows Exported:            $totalRows"
Write-Host "Groups Reviewed:          $uniqueGroups"
Write-Host "User Members:             $userMembers"
Write-Host "Nested Group Members:     $groupMembers"
Write-Host "Groups With No Members:   $emptyGroups"
Write-Host "Errors:                   $errorRows"
Write-Host ""
