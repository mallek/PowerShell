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
    .PARAMETER Title
        Tab title. Defaults to the handoff file's base name.
    .PARAMETER Window
        Named Windows Terminal window. Defaults to marvin-relay.
    .PARAMETER SkipPermissions
        Add --dangerously-skip-permissions (forward authoring phases only).
    .PARAMETER DryRun
        Return the exact command string without launching anything.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HandoffFile,
        [Parameter(Mandatory)][ValidateSet('opus', 'sonnet', 'fable', 'haiku')][string]$Model,
        [Parameter(Mandatory)][string]$WorkDir,
        [string]$Title,
        [string]$Window = 'marvin-relay',
        [switch]$SkipPermissions,
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

    $claude = "claude --model $Model"
    if ($SkipPermissions) {
        $claude += ' --dangerously-skip-permissions'
    }
    $claude += " '$prompt'"

    $wtArgs = @(
        '-w', $Window,
        'new-tab',
        '-d', $resolvedDir,
        '--title', $Title,
        '--', 'pwsh.exe', '-NoExit', '-Command', $claude
    )

    $display = 'wt.exe ' + (($wtArgs | ForEach-Object {
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
