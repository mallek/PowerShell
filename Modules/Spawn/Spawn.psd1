@{
    RootModule = 'Spawn.psm1'
    ModuleVersion = '1.1.0'
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
