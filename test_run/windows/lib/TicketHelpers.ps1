function Prompt-TicketBundle {
    [CmdletBinding()]
    param(
        [switch]$RequirePrimary
    )

    function Read-Ticket([string]$label, [switch]$required) {
        while ($true) {
            $val = Read-Host "$label (e.g. INC123456 / REQ123456 / RITM123456 / CHG123456 / TERM123456)"
            if (-not $val -and $required) {
                Write-Host "[ERROR] $label is required." -ForegroundColor Red
                continue
            }
            if (-not $val) { return "" }

            if ($val -match '^(INC|REQ|RITM|TASK|CHG|TERM)\d+$') {
                return $val.ToUpper()
            } else {
                Write-Host "[WARN] Ticket format looks off. Continue anyway? (Y/N)" -ForegroundColor Yellow
                $ans = Read-Host
                if ($ans -match '^[Yy]$') { return $val }
            }
        }
    }

    $primary = Read-Ticket "Primary Ticket" -required:$RequirePrimary
    $work    = Read-Ticket "Work Ticket"    -required:$false
    $note    = Read-Host "Action/Work Note (optional)"

    [PSCustomObject]@{
        PrimaryTicket = $primary
        WorkTicket    = $work
        Note          = $note
        Timestamp     = (Get-Date)
    }
}

function Format-TicketStamp {
    param($Bundle)

    $parts = @()

    if ($Bundle.PrimaryTicket) { $parts += "SNOW_PRIMARY:$($Bundle.PrimaryTicket)" }
    if ($Bundle.WorkTicket)    { $parts += "SNOW_WORK:$($Bundle.WorkTicket)" }
    if ($Bundle.Note)          { $parts += "NOTE:$($Bundle.Note)" }

    if ($parts.Count -eq 0) { return "" }

    return ($parts -join " | ")
}

function Parse-TicketStamp {
    param([string]$Description)

    $primary = ""
    $work    = ""

    if ($Description -match 'SNOW_PRIMARY:([A-Z]+\d+)') { $primary = $matches[1] }
    if ($Description -match 'SNOW_WORK:([A-Z]+\d+)')    { $work    = $matches[1] }

    [PSCustomObject]@{
        PrimaryTicket = $primary
        WorkTicket    = $work
        Raw           = $Description
    }
}
