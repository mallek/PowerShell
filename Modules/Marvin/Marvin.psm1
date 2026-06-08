#
# Marvin PowerShell Module
# MARVIN - Manages Appointments, Reads Various Important Notifications
# AI Chief of Staff
#

$script:MarvinHome = Join-Path $env:USERPROFILE 'marvin'

function Show-MarvinBanner {
    Import-Module Write-Ascii -ErrorAction SilentlyContinue
    if (Get-Command Write-Ascii -ErrorAction SilentlyContinue) {
        Write-Ascii 'MARVIN' -ForegroundColor Yellow
    } else {
        Write-Host 'M A R V I N' -ForegroundColor Yellow
    }
    Write-Host '  AI Chief of Staff' -ForegroundColor DarkGray
    Write-Host ''
}

function marvin {
    <#
    .SYNOPSIS
        Launch MARVIN - AI Chief of Staff
    .DESCRIPTION
        Opens Claude Code in the MARVIN workspace directory.
    #>
    Show-MarvinBanner
    Set-Location $script:MarvinHome
    claude @args
}

function mcode {
    <#
    .SYNOPSIS
        Open MARVIN in your IDE (Cursor, VS Code, etc.)
    .DESCRIPTION
        Opens the MARVIN workspace in your default code editor.
    #>
    Set-Location $script:MarvinHome
    code .
}

Export-ModuleMember -Function @('marvin', 'mcode', 'Show-MarvinBanner')
