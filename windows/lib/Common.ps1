function Get-BayouFindsWindowsRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot
    )

    $root = Split-Path -Parent $ScriptRoot
    if ((Split-Path -Leaf $ScriptRoot) -ieq "windows") {
        $root = $ScriptRoot
    }

    return $root
}

function Resolve-BayouFindsOutputPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot,

        [string]$OutDir = ".\output"
    )

    if ([System.IO.Path]::IsPathRooted($OutDir)) {
        return [System.IO.Path]::GetFullPath($OutDir)
    }

    $windowsRoot = Get-BayouFindsWindowsRoot -ScriptRoot $ScriptRoot
    $relativeOutDir = $OutDir -replace '^[.][\\/]*', ''

    return [System.IO.Path]::GetFullPath((Join-Path $windowsRoot $relativeOutDir))
}

function Initialize-BayouFindsOutputDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot,

        [string]$OutDir = ".\output"
    )

    $resolvedPath = Resolve-BayouFindsOutputPath -ScriptRoot $ScriptRoot -OutDir $OutDir
    New-Item -ItemType Directory -Force -Path $resolvedPath | Out-Null
    return $resolvedPath
}

function Set-BayouFindsReportContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyString()]
        [string]$Text = ""
    )

    Set-Content -Path $Path -Value $Text -Encoding UTF8
}

function Add-BayouFindsReportContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyString()]
        [string]$Text = ""
    )

    Add-Content -Path $Path -Value $Text -Encoding UTF8
}

function Test-BayouFindsCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$FriendlyName = $Name
    )

    if (Get-Command $Name -ErrorAction SilentlyContinue) {
        return $true
    }

    Write-Host "[WARN] $FriendlyName is not available on this host." -ForegroundColor Yellow
    return $false
}

function Import-BayouFindsActiveDirectoryModule {
    [CmdletBinding()]
    param(
        [switch]$Quiet
    )

    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        return $true
    }
    catch {
        if (-not $Quiet) {
            Write-Host "[ERROR] ActiveDirectory module not found. Run this on a domain-joined system with RSAT/AD tools installed." -ForegroundColor Red
        }
        return $false
    }
}
