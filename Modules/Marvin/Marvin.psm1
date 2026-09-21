#
# Marvin PowerShell Module
# MARVIN - Manages Appointments, Reads Various Important Notifications
# AI Chief of Staff
#

$script:MarvinHome = Join-Path $env:USERPROFILE 'marvin'

# Windows Terminal window that MARVIN and its spawned agent tabs share.
# Must match the Spawn module's default -Window, or `spawn` opens its tabs in a
# separate window instead of joining this session's tab group.
$script:MarvinWindow = 'agent-relay'

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
        Opens Claude Code in the MARVIN workspace directory, in the CURRENT shell and
        the current Windows Terminal window. Use this when a terminal is already open.
        To open MARVIN in the shared agent-relay window (so `spawn` tabs join it),
        use Start-MarvinSession / mstart instead.
        All arguments are forwarded to claude untouched.
    #>
    Show-MarvinBanner
    Set-Location $script:MarvinHome
    claude @args
}

function Start-MarvinSession {
    <#
    .SYNOPSIS
        Open MARVIN in the shared agent-relay Windows Terminal window.
    .DESCRIPTION
        Entry point for the keyboard macro and any desktop shortcut. Opens a tab in the
        named window (creating that window if it does not exist yet) and runs MARVIN in
        it.

        The point of the named window is that the Spawn module defaults to the same
        name, so `spawn` opens its agent tabs as siblings of this session rather than
        in a separate window. `wt -w <name>` targets an existing window by name and
        creates it when absent, which is why a session started any other way ends up
        somewhere else.

        Keep the window name here and in the Spawn module in sync. Putting it in the
        module rather than in the macro means it travels with the repo to every machine
        and the macro never needs editing again.
    .PARAMETER Window
        Named Windows Terminal window to open in. Defaults to agent-relay.
    .PARAMETER Name
        Remote Control name for the session. Defaults to MARVIN. The Spawn module names
        every session it launches, so without this the MARVIN session is the one tab in
        the group that is not findable or steerable from the app.
    .PARAMETER NoRemoteControl
        Opt out of Remote Control, matching the Spawn module's switch of the same name.
    .PARAMETER DryRun
        Return the command string without launching anything.
    #>
    [CmdletBinding()]
    param(
        [string]$Window = $script:MarvinWindow,
        [string]$Name = 'MARVIN',
        [switch]$NoRemoteControl,
        [switch]$DryRun
    )

    if (-not (Test-Path -LiteralPath $script:MarvinHome -PathType Container)) {
        throw "MARVIN home not found: $script:MarvinHome"
    }

    # Same inherited-environment corrections the Spawn module makes, for the same
    # reason: if this is invoked from inside an agent tool call, the tool environment
    # has NO_COLOR=1 and CLAUDE_CODE_CHILD_SESSION set, and the new tab inherits both -
    # the first renders MARVIN monochrome, the second makes its claude treat itself as a
    # nested child and skip writing a transcript, so the session can never be recovered
    # with /resume. Clear both and set the documented persistence override.
    $prep = "`$env:NO_COLOR=`$null; `$env:FORCE_COLOR='3'; `$env:COLORTERM='truecolor'; " +
            "`$env:CLAUDE_CODE_CHILD_SESSION=`$null; `$env:CLAUDE_CODE_FORCE_SESSION_PERSISTENCE='1'"

    # `marvin` forwards @args straight through to claude, so the Remote Control flag
    # rides that passthrough and the function itself needs no changes. Sanitize the
    # name the same way Spawn does, so it cannot break the command-string quoting.
    $marvin = 'marvin'
    if (-not $NoRemoteControl) {
        $rcName = $Name -replace '[^A-Za-z0-9._-]', '-'
        $marvin += " --remote-control $rcName"
    }

    $command = "$prep; $marvin"

    # wt.exe treats ';' as its own command/tab separator even inside a quoted argument
    # after '--', so the multi-statement command above would be shredded into extra
    # tabs. Base64/UTF-16LE encode it: the payload is pure alphanumerics, so nothing
    # survives to reach wt.exe's parser.
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))

    $wtArgs = @(
        '-w', $Window,
        'new-tab',
        '-d', $script:MarvinHome,
        '--title', 'MARVIN',
        '--', 'pwsh.exe', '-NoExit', '-EncodedCommand', $encoded
    )

    if ($DryRun) {
        # Human-readable rendering only - shows the DECODED command, not the Base64 blob.
        $displayArgs = @(
            '-w', $Window,
            'new-tab',
            '-d', $script:MarvinHome,
            '--title', 'MARVIN',
            '--', 'pwsh.exe', '-NoExit', '-Command', $command
        )
        return 'wt.exe ' + (($displayArgs | ForEach-Object {
            if ($_ -match '\s') {
                '"' + $_ + '"'
            } else {
                $_
            }
        }) -join ' ')
    }

    & wt.exe @wtArgs
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

Set-Alias -Name mstart -Value Start-MarvinSession
Export-ModuleMember -Function @('marvin', 'mcode', 'Show-MarvinBanner', 'Start-MarvinSession') -Alias 'mstart'
