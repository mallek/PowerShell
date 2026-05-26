#
# Rocky PowerShell Module
# ROCKY - Skunkworks Lab Partner
# Curious Eridian engineer for tinkering projects
#

$script:RockyHome = Join-Path $env:USERPROFILE 'rocky'

function Show-RockyBanner {
    $rainbowColors = @('Red', 'Yellow', 'Green', 'Cyan', 'Blue', 'Magenta')

    Import-Module Write-Ascii -ErrorAction SilentlyContinue
    if (Get-Command Write-Ascii -ErrorAction SilentlyContinue) {
        # Get the ASCII art as a string, then colorize each line
        $asciiLines = (Write-Ascii 'ROCKY' -ForegroundColor White 6>&1 | Out-String) -split "`n"
        $lineIndex = 0
        foreach ($line in $asciiLines) {
            if ($line.Trim()) {
                $color = $rainbowColors[$lineIndex % $rainbowColors.Count]
                Write-Host $line -ForegroundColor $color
                $lineIndex++
            }
        }
    } else {
        # Fallback: colorize each letter
        $letters = 'R', 'O', 'C', 'K', 'Y'
        for ($i = 0; $i -lt $letters.Count; $i++) {
            $color = $rainbowColors[$i % $rainbowColors.Count]
            Write-Host "$($letters[$i]) " -ForegroundColor $color -NoNewline
        }
        Write-Host ''
    }
    Write-Host '  Skunkworks Lab Partner' -ForegroundColor DarkGray
    Write-Host ''
}

function rocky {
    <#
    .SYNOPSIS
        Launch ROCKY - Skunkworks Lab Partner
    .DESCRIPTION
        Opens Claude Code in the ROCKY workspace directory.
        No MCP servers needed -- just pure tinkering.
    #>
    Show-RockyBanner
    Set-Location $script:RockyHome
    claude @args
}

Export-ModuleMember -Function @('rocky', 'Show-RockyBanner')
