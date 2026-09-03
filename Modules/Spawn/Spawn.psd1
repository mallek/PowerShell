@{
    RootModule = 'Spawn.psm1'
    ModuleVersion = '1.3.0'
    GUID = 'a7f3c9d2-5e81-4b6a-9c4d-2f8e1a3b7d60'
    Author = 'Travis Haley'
    CompanyName = 'Personal'
    Copyright = '(c) 2026 Travis Haley. All rights reserved.'
    Description = 'Spawn - launches a fresh agent CLI session in a new Windows Terminal tab, pointed at a self-contained handoff/kickoff file.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Start-AgentSession')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @('spawn')
    PrivateData = @{
        PSData = @{
            Tags = @('AI', 'Claude', 'Productivity', 'Spawn', 'Handoff')
            ReleaseNotes = @'
Version 1.3.0
- Effort parameter: --effort low/medium/high/xhigh, independent of Model (Model sets the capability ceiling, Effort sets how much reasoning is spent under it). 'max' is rejected at launch time on purpose - it is an in-session escalation made by someone watching the work, not a level chosen blind.
- Clear inherited NO_COLOR and force truecolor (FORCE_COLOR=3, COLORTERM=truecolor). Spawning from inside an agent tool call leaked NO_COLOR=1 into the new tab, rendering the spawned CLI monochrome.
- The child command is now passed as -EncodedCommand (Base64/UTF-16LE). wt.exe treats ';' as its own command separator even inside a quoted argument after '--', so a multi-statement command string was being shredded into extra tabs.
- Transcript persistence moved into the child command, which the -EncodedCommand change makes safe. CLAUDE_CODE_CHILD_SESSION is now cleared as well as CLAUDE_CODE_FORCE_SESSION_PERSISTENCE being set, and neither one mutates the launching shell's environment any more (1.2.1 had to set it on this process because of the semicolon constraint that no longer applies).

Version 1.2.1
- Force transcript persistence on spawned sessions. wt.exe inherited CLAUDE_CODE_CHILD_SESSION from the launching Claude Code process, so the new session disabled its own transcript and could never be recovered with /resume. CLAUDE_CODE_FORCE_SESSION_PERSISTENCE is now set on this process before the launch so the whole tree inherits it.

Version 1.2.0
- Remote Control is now ON by default (findable/steerable from the app - the right default for phone/away work). Opt out with -NoRemoteControl for a truly fire-and-forget sweep or an account without Remote Control. Replaces the old opt-in -RemoteControl switch.

Version 1.1.0
- RemoteControl switch: --remote-control named after the tab title (always named, or the flag would swallow the positional prompt)

Version 1.0.1
- Neutral default window name (agent-relay)

Version 1.0.0
- Start-AgentSession: open a new Windows Terminal tab running the agent CLI
- spawn alias
- DryRun mode for confirm-first launches
'@
        }
    }
}
