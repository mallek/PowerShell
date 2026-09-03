#
# Spawn PowerShell Module
# Launches a fresh agent CLI session in a new Windows Terminal tab,
# pointed at a self-contained handoff/kickoff file.
#

function Start-AgentSession {
    <#
    .SYNOPSIS
        Spawn a fresh Claude Code session in a new Windows Terminal tab.
    .DESCRIPTION
        Builds the wt.exe incantation that opens a new tab, sets the working
        directory (so the repo CLAUDE.md loads), and runs the agent CLI with an
        auto-submitting prompt that points the new session at its handoff file.
        The prompt is a fixed string so no free-text punctuation can break the
        launch. Run from PowerShell only.
    .PARAMETER HandoffFile
        Absolute path to the kickoff .md the new session reads. Must exist.
    .PARAMETER Model
        Target model tier: opus, sonnet, fable, or haiku.
    .PARAMETER WorkDir
        Absolute path to launch in (wt -d). Must exist.
    .PARAMETER Effort
        Reasoning effort for the session: low, medium, high, or xhigh. Omit to leave
        the CLI default in place. Independent of Model - Model sets the capability
        ceiling, Effort sets how much reasoning is spent under it.
        'max' is deliberately NOT accepted here: it is an in-session escalation, made
        by someone watching the work, not a level chosen blind at launch time.
    .PARAMETER Title
        Tab title. Defaults to the handoff file's base name.
    .PARAMETER Window
        Named Windows Terminal window. Defaults to agent-relay.
    .PARAMETER SkipPermissions
        Add --dangerously-skip-permissions (forward authoring phases only).
    .PARAMETER NoRemoteControl
        Opt out of Remote Control. By default every session launches with
        --remote-control (named after the tab title) so it is findable and
        steerable from the app - the right default for phone/away work. Pass
        -NoRemoteControl for a truly fire-and-forget sweep, or on an account
        where Remote Control is not available.
    .PARAMETER DryRun
        Return the exact command string without launching anything.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HandoffFile,
        [Parameter(Mandatory)][ValidateSet('opus', 'sonnet', 'fable', 'haiku')][string]$Model,
        [Parameter(Mandatory)][string]$WorkDir,
        [string]$Title,
        [string]$Window = 'agent-relay',
        [ValidateSet('low', 'medium', 'high', 'xhigh')][string]$Effort,
        [switch]$SkipPermissions,
        [switch]$NoRemoteControl,
        [switch]$DryRun
    )

    if (-not (Test-Path -LiteralPath $HandoffFile -PathType Leaf)) {
        throw "HandoffFile not found: $HandoffFile"
    }
    if (-not (Test-Path -LiteralPath $WorkDir -PathType Container)) {
        throw "WorkDir not found: $WorkDir"
    }

    $resolvedFile = (Resolve-Path -LiteralPath $HandoffFile).Path
    $resolvedDir = (Resolve-Path -LiteralPath $WorkDir).Path

    if (-not $Title) {
        $Title = [System.IO.Path]::GetFileNameWithoutExtension($resolvedFile)
    }

    $prompt = "Read $resolvedFile and do what it says."

    # Two inherited environment variables have to be corrected on the CLI's own
    # process, and both are set here in the child command rather than on this one.
    #
    # NO_COLOR: when spawn is launched from inside an agent tool call, the tool
    # environment has NO_COLOR=1 set and the new WT tab inherits it, so the spawned
    # CLI renders monochrome. A shell-launched tab (e.g. a keyboard macro) has no
    # NO_COLOR and is unaffected. Clear it and force truecolor: FORCE_COLOR=3 forces
    # the color level, COLORTERM=truecolor keeps the palette at 16m.
    #
    # CLAUDE_CODE_CHILD_SESSION: inherited the same way, and it makes the new
    # session's claude disable transcript persistence - it looks like a nested child
    # rather than a real interactive session, so the transcript is never written and
    # /resume can never recover it. Clear the marker and set the documented override.
    #
    # Setting these in the child command is only safe because of the -EncodedCommand
    # below. wt.exe treats ';' as its own command separator even inside a quoted
    # argument after '--', so a plain "set env; run claude" string gets split apart;
    # Base64 removes that constraint, which is why these do not need to mutate the
    # launching shell's own environment to take effect.
    $prep = "`$env:NO_COLOR=`$null; `$env:FORCE_COLOR='3'; `$env:COLORTERM='truecolor'; " +
            "`$env:CLAUDE_CODE_CHILD_SESSION=`$null; `$env:CLAUDE_CODE_FORCE_SESSION_PERSISTENCE='1'"

    $claude = "$prep; claude --model $Model"
    if ($Effort) {
        $claude += " --effort $Effort"
    }
    if ($SkipPermissions) {
        $claude += ' --dangerously-skip-permissions'
    }
    if (-not $NoRemoteControl) {
        # RC is on by default so the session is findable/steerable from the app.
        # The flag's name value is optional and the prompt is positional, so an
        # unnamed --remote-control would swallow the prompt as its name. Always
        # pass a name; sanitize so it cannot break the command-string quoting.
        $rcName = $Title -replace '[^A-Za-z0-9._-]', '-'
        $claude += " --remote-control $rcName"
    }
    $claude += " '$prompt'"

    # wt.exe treats ';' as its OWN command/tab separator, so a -Command string that
    # contains semicolons (the env prep does) gets shredded into multiple tabs before
    # pwsh ever sees it. Encode the whole command as Base64/UTF-16LE and pass it via
    # -EncodedCommand: the payload is pure alphanumerics, so no semicolon, quote, or
    # space survives to reach wt.exe's parser.
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($claude))

    $wtArgs = @(
        '-w', $Window,
        'new-tab',
        '-d', $resolvedDir,
        '--title', $Title,
        '--', 'pwsh.exe', '-NoExit', '-EncodedCommand', $encoded
    )

    # Human-readable rendering for confirm-first display only. Shows the DECODED
    # command the spawned pwsh will run, not the Base64 blob - the authoritative
    # launch is the $wtArgs splat above. PowerShell quotes those args natively, so
    # this string is an approximation, not a byte-exact copy of what runs.
    $displayArgs = @(
        '-w', $Window,
        'new-tab',
        '-d', $resolvedDir,
        '--title', $Title,
        '--', 'pwsh.exe', '-NoExit', '-Command', $claude
    )
    $display = 'wt.exe ' + (($displayArgs | ForEach-Object {
        if ($_ -match '\s') {
            '"' + $_ + '"'
        } else {
            $_
        }
    }) -join ' ')

    if ($DryRun) {
        return $display
    }

    & wt.exe @wtArgs
}

Set-Alias -Name spawn -Value Start-AgentSession
Export-ModuleMember -Function 'Start-AgentSession' -Alias 'spawn'
