[CmdletBinding()]
param(
    [string[]]$ComputerName = @($env:COMPUTERNAME),
    [string]$OutDir = ".\output",
    [switch]$MockMode
)

$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function New-LocalAdminRow {
    param(
        [string]$ComputerName,
        [string]$GroupName,
        [string]$MemberName,
        [string]$MemberSID,
        [string]$PrincipalSource,
        [string]$ObjectClass,
        [string]$Domain,
        [string]$IsLocalAccount,
        [string]$Status,
        [string]$ADDisplayName,
        [string]$ADTitle,
        [string]$ADDepartment,
        [string]$ADDescription,
        [string]$ADCompany,
        [string]$ADEnabled,
        [string]$ADLastLogonDate,
        [string]$DaysSinceLastLogon,
        [string]$ADGroupScope,
        [string]$ADGroupCategory,
        [string]$ADDistinguishedName,
        [string]$Source
    )

    [PSCustomObject]@{
        ComputerName          = $ComputerName
        GroupName             = $GroupName
        MemberName            = $MemberName
        MemberSID             = $MemberSID
        PrincipalSource       = $PrincipalSource
        ObjectClass           = $ObjectClass
        Domain                = $Domain
        IsLocalAccount        = $IsLocalAccount
        Status                = $Status
        ADDisplayName         = $ADDisplayName
        ADTitle               = $ADTitle
        ADDepartment          = $ADDepartment
        ADDescription         = $ADDescription
        ADCompany             = $ADCompany
        ADEnabled             = $ADEnabled
        ADLastLogonDate       = $ADLastLogonDate
        DaysSinceLastLogon    = $DaysSinceLastLogon
        ADGroupScope          = $ADGroupScope
        ADGroupCategory       = $ADGroupCategory
        ADDistinguishedName   = $ADDistinguishedName
        Source                = $Source
    }
}

function Get-DaysSince {
    param($DateValue)

    if (-not $DateValue) { return "" }

    try {
        return [string]((New-TimeSpan -Start $DateValue -End (Get-Date)).Days)
    }
    catch {
        return ""
    }
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Ensure-Directory -Path $OutDir
$csvPath = Join-Path $OutDir "Local_Admin_Audit_Report_$timestamp.csv"

$rows = @()

if ($MockMode) {
    Write-Host "[INFO] Running in MockMode (no AD required)" -ForegroundColor Cyan

    $rows += New-LocalAdminRow `
        -ComputerName "WKSTN-001" `
        -GroupName "Administrators" `
        -MemberName "EXAMPLE\aadmin" `
        -MemberSID "S-1-5-21-1111111111-2222222222-3333333333-1105" `
        -PrincipalSource "ActiveDirectory" `
        -ObjectClass "User" `
        -Domain "EXAMPLE" `
        -IsLocalAccount "False" `
        -Status "Resolved" `
        -ADDisplayName "Alice Admin" `
        -ADTitle "Systems Administrator" `
        -ADDepartment "IT" `
        -ADDescription "SNOW_PRIMARY:TERM001245 | SNOW_WORK:INC003889 | NOTE:Access review sample" `
        -ADCompany "Example Co" `
        -ADEnabled "True" `
        -ADLastLogonDate ((Get-Date).AddDays(-3).ToString("s")) `
        -DaysSinceLastLogon "3" `
        -ADGroupScope "" `
        -ADGroupCategory "" `
        -ADDistinguishedName "CN=Alice Admin,OU=Admins,DC=example,DC=local" `
        -Source "MockMode"

    $rows += New-LocalAdminRow `
        -ComputerName "WKSTN-001" `
        -GroupName "Administrators" `
        -MemberName "EXAMPLE\IT_Admins" `
        -MemberSID "S-1-5-21-1111111111-2222222222-3333333333-2100" `
        -PrincipalSource "ActiveDirectory" `
        -ObjectClass "Group" `
        -Domain "EXAMPLE" `
        -IsLocalAccount "False" `
        -Status "Resolved" `
        -ADDisplayName "IT_Admins" `
        -ADTitle "" `
        -ADDepartment "" `
        -ADDescription "Privileged workstation administrators" `
        -ADCompany "" `
        -ADEnabled "" `
        -ADLastLogonDate "" `
        -DaysSinceLastLogon "" `
        -ADGroupScope "Global" `
        -ADGroupCategory "Security" `
        -ADDistinguishedName "CN=IT_Admins,OU=Groups,DC=example,DC=local" `
        -Source "MockMode"

    $rows += New-LocalAdminRow `
        -ComputerName "WKSTN-001" `
        -GroupName "Administrators" `
        -MemberName "S-1-5-21-9999999999-8888888888-7777777777-1234" `
        -MemberSID "S-1-5-21-9999999999-8888888888-7777777777-1234" `
        -PrincipalSource "Unknown" `
        -ObjectClass "Unknown" `
        -Domain "" `
        -IsLocalAccount "" `
        -Status "Orphaned SID" `
        -ADDisplayName "" `
        -ADTitle "" `
        -ADDepartment "" `
        -ADDescription "" `
        -ADCompany "" `
        -ADEnabled "" `
        -ADLastLogonDate "" `
        -DaysSinceLastLogon "" `
        -ADGroupScope "" `
        -ADGroupCategory "" `
        -ADDistinguishedName "" `
        -Source "MockMode"
}
else {
    $adAvailable = $false

    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $adAvailable = $true
    }
    catch {
        $adAvailable = $false
    }

    foreach ($computer in $ComputerName) {
        try {
            $members = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop

            foreach ($member in $members) {
                $memberName = [string]$member.Name
                $memberSid = [string]$member.SID
                $source = [string]$member.PrincipalSource
                $objectClass = [string]$member.ObjectClass
                $domain = ""
                $isLocal = ""

                if ($memberName -match '\\') {
                    $domain = ($memberName -split '\\')[0]
                }

                if ($source -eq "Local") {
                    $isLocal = "True"
                }
                elseif ($source -eq "ActiveDirectory") {
                    $isLocal = "False"
                }

                $status = "Resolved"
                if ($memberName -match '^S-\d-\d+') {
                    $status = "Orphaned SID"
                }

                $adDisplayName = ""
                $adTitle = ""
                $adDepartment = ""
                $adDescription = ""
                $adCompany = ""
                $adEnabled = ""
                $adLastLogonDate = ""
                $daysSinceLastLogon = ""
                $adGroupScope = ""
                $adGroupCategory = ""
                $adDN = ""

                if ($adAvailable -and $source -eq "ActiveDirectory" -and $status -eq "Resolved") {
                    try {
                        if ($objectClass -eq "User") {
                            $sam = ($memberName -split '\\')[-1]
                            $adUser = Get-ADUser -Identity $sam -Properties DisplayName,Title,Department,Description,Company,Enabled,LastLogonDate,DistinguishedName -ErrorAction Stop

                            $adDisplayName = [string]$adUser.DisplayName
                            $adTitle = [string]$adUser.Title
                            $adDepartment = [string]$adUser.Department
                            $adDescription = [string]$adUser.Description
                            $adCompany = [string]$adUser.Company
                            $adEnabled = [string]$adUser.Enabled
                            $adLastLogonDate = [string]$adUser.LastLogonDate
                            $daysSinceLastLogon = Get-DaysSince $adUser.LastLogonDate
                            $adDN = [string]$adUser.DistinguishedName
                        }
                        elseif ($objectClass -eq "Group") {
                            $sam = ($memberName -split '\\')[-1]
                            $adGroup = Get-ADGroup -Identity $sam -Properties Description,GroupScope,GroupCategory,DistinguishedName -ErrorAction Stop

                            $adDisplayName = [string]$adGroup.Name
                            $adDescription = [string]$adGroup.Description
                            $adGroupScope = [string]$adGroup.GroupScope
                            $adGroupCategory = [string]$adGroup.GroupCategory
                            $adDN = [string]$adGroup.DistinguishedName
                        }
                    }
                    catch {
                        $status = "AD Enrichment Failed"
                        $adDescription = $_.Exception.Message
                    }
                }
                elseif (-not $adAvailable -and $source -eq "ActiveDirectory") {
                    $status = "AD Module Unavailable"
                }

                $rows += New-LocalAdminRow `
                    -ComputerName $computer `
                    -GroupName "Administrators" `
                    -MemberName $memberName `
                    -MemberSID $memberSid `
                    -PrincipalSource $source `
                    -ObjectClass $objectClass `
                    -Domain $domain `
                    -IsLocalAccount $isLocal `
                    -Status $status `
                    -ADDisplayName $adDisplayName `
                    -ADTitle $adTitle `
                    -ADDepartment $adDepartment `
                    -ADDescription $adDescription `
                    -ADCompany $adCompany `
                    -ADEnabled $adEnabled `
                    -ADLastLogonDate $adLastLogonDate `
                    -DaysSinceLastLogon $daysSinceLastLogon `
                    -ADGroupScope $adGroupScope `
                    -ADGroupCategory $adGroupCategory `
                    -ADDistinguishedName $adDN `
                    -Source "LocalMachine"
            }
        }
        catch {
            $rows += New-LocalAdminRow `
                -ComputerName $computer `
                -GroupName "Administrators" `
                -MemberName "<ERROR>" `
                -MemberSID "" `
                -PrincipalSource "" `
                -ObjectClass "" `
                -Domain "" `
                -IsLocalAccount "" `
                -Status $_.Exception.Message `
                -ADDisplayName "" `
                -ADTitle "" `
                -ADDepartment "" `
                -ADDescription "" `
                -ADCompany "" `
                -ADEnabled "" `
                -ADLastLogonDate "" `
                -DaysSinceLastLogon "" `
                -ADGroupScope "" `
                -ADGroupCategory "" `
                -ADDistinguishedName "" `
                -Source "LocalMachine"
        }
    }
}

$rows | Sort-Object ComputerName, MemberName | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$totalRows = $rows.Count
$resolvedRows = ($rows | Where-Object { $_.Status -eq "Resolved" }).Count
$orphanedSidRows = ($rows | Where-Object { $_.Status -eq "Orphaned SID" }).Count
$adUnavailableRows = ($rows | Where-Object { $_.Status -eq "AD Module Unavailable" }).Count
$adFailedRows = ($rows | Where-Object { $_.Status -eq "AD Enrichment Failed" }).Count
$errorRows = ($rows | Where-Object { $_.MemberName -eq "<ERROR>" }).Count

Write-Host ""
Write-Host "Local Admin Audit complete." -ForegroundColor Green
Write-Host "CSV: $csvPath"
Write-Host ""
Write-Host "Summary"
Write-Host "-------"
Write-Host "Rows Exported:            $totalRows"
Write-Host "Resolved Rows:            $resolvedRows"
Write-Host "Orphaned SID Rows:        $orphanedSidRows"
Write-Host "AD Module Unavailable:    $adUnavailableRows"
Write-Host "AD Enrichment Failed:     $adFailedRows"
Write-Host "Errors:                   $errorRows"
Write-Host ""
