param(
    [string]$SqlServer = "localhost"
)

$ErrorActionPreference = "Continue"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "lib\Common.ps1")

$ScriptVersion = "v1.0"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$RunStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Operator = "$env:USERDOMAIN\$env:USERNAME"
$Computer = $env:COMPUTERNAME
$Domain = $env:USERDOMAIN
$OutputDir = Initialize-BayouFindsOutputDirectory -ScriptRoot $PSScriptRoot

$ReportFile = Join-Path $OutputDir "dynamics_gp_database_inventory_$RunStamp.txt"

function Write-Line {
    param([string]$Text)
    $Text | Add-Content $ReportFile
}

"══════════════════════════════════════" | Set-Content $ReportFile
"DYNAMICS GP / GREAT PLAINS DATABASE INVENTORY" | Add-Content $ReportFile
"══════════════════════════════════════" | Add-Content $ReportFile
"" | Add-Content $ReportFile

Write-Line "Generated: $Timestamp"
Write-Line "Operator: $Operator"
Write-Line "Computer: $Computer"
Write-Line "Domain: $Domain"
Write-Line "SQL Server: $SqlServer"
Write-Line "Script Version: $ScriptVersion"
Write-Line ""

Write-Line "PURPOSE"
Write-Line "-------"
Write-Line "Inventory Microsoft Dynamics GP / Great Plains SQL databases for financial-system audit visibility."
Write-Line ""

$query = @"
SELECT name, create_date, compatibility_level, state_desc, recovery_model_desc
FROM sys.databases
ORDER BY name;
"@

try {
    $databases = Invoke-Sqlcmd -ServerInstance $SqlServer -Query $query -ErrorAction Stop

    Write-Line "DATABASE INVENTORY"
    Write-Line "------------------"

    foreach ($db in $databases) {
        Write-Line "- $($db.name) | State: $($db.state_desc) | Recovery: $($db.recovery_model_desc) | Created: $($db.create_date)"
    }

    Write-Line ""
    Write-Line "POTENTIAL DYNAMICS GP DATABASES"
    Write-Line "-------------------------------"

    $gpCandidates = $databases | Where-Object {
        $_.name -eq "DYNAMICS" -or
        $_.name -match "TWO|GP|DYN|COMPANY|LIVE|TEST"
    }

    if ($gpCandidates) {
        foreach ($db in $gpCandidates) {
            Write-Line "- $($db.name)"
        }
    } else {
        Write-Line "- No obvious Dynamics GP database names detected."
    }
}
catch {
    Write-Line "ERROR"
    Write-Line "-----"
    Write-Line "Unable to query SQL Server using Invoke-Sqlcmd."
    Write-Line "Reason: $($_.Exception.Message)"
    Write-Line ""
    Write-Line "COMMON CAUSES"
    Write-Line "-------------"
    Write-Line "- SQL Server PowerShell module is not installed"
    Write-Line "- Operator lacks SQL permissions"
    Write-Line "- SQL Server name/instance is incorrect"
    Write-Line "- Firewall or InfoSec policy blocks SQL access"
    Write-Line "- Run from a server/admin workstation with SQL tools installed"
}

Write-Line ""
Write-Line "WHERE TO REVIEW (AUDITOR GUIDANCE)"
Write-Line "-----------------------------------"
Write-Line "- SQL Server Management Studio (SSMS)"
Write-Line "- SQL Server → Databases"
Write-Line "- DYNAMICS system database"
Write-Line "- Company databases linked to Dynamics GP"
Write-Line "- SQL Security → Logins"
Write-Line "- SQL Server Agent jobs for GP maintenance/backups"
Write-Line "- Backup jobs and recovery model"
Write-Line "- GP application security roles if available"

Write-Line ""
Write-Line "NOTE"
Write-Line "----"
Write-Line "This script inventories SQL databases and identifies likely GP-related databases by common naming patterns."
Write-Line "Validate findings with the Dynamics GP administrator or DBA."

Write-Line ""
Write-Line "──────────────────────────────────────"
Write-Line "© BayouFinds.com - All rights reserved."
Write-Line "support@bayoufinds.com | https://bayoufinds.com"

Write-Host "Report complete: $ReportFile"
