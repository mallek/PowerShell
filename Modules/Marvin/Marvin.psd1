@{
    RootModule = 'Marvin.psm1'
    ModuleVersion = '1.2.0'
    GUID = 'b4e2f8a1-3c7d-4a9e-8f1b-6d5c2e9a7b4f'
    Author = 'Travis Haley'
    CompanyName = 'Personal'
    Copyright = '(c) 2026 Travis Haley. All rights reserved.'
    Description = 'MARVIN - Manages Appointments, Reads Various Important Notifications. AI Chief of Staff powered by Claude Code.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('marvin', 'mcode', 'Show-MarvinBanner', 'Start-MarvinSession')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @('mstart')
    PrivateData = @{
        PSData = @{
            Tags = @('AI', 'Claude', 'Productivity', 'Assistant', 'MARVIN')
            ReleaseNotes = @'
Version 1.2.0
- Start-MarvinSession now names the session for Remote Control (--remote-control, default 'MARVIN'), passed through `marvin`'s existing @args forwarding so that function needed no changes. Spawn names every session it launches, so without this the MARVIN session was the one tab in the group that was not findable or steerable from the app. Override with -Name, or opt out with -NoRemoteControl to match Spawn's switch of the same name. The name is sanitized the same way Spawn sanitizes its own.

Version 1.1.0
- Start-MarvinSession (alias mstart): opens MARVIN in the shared 'agent-relay' Windows Terminal window, creating that window if it does not exist. This is the entry point the keyboard macro and any desktop shortcut should call. The Spawn module defaults to the same window name, so `spawn` now opens its agent tabs as siblings of the MARVIN session instead of in a separate window.
- The window name lives in the module rather than in the macro, so it travels with the repo to every machine and the macro never needs editing again. Keep $script:MarvinWindow and the Spawn module's default -Window in sync.
- Start-MarvinSession clears inherited NO_COLOR and CLAUDE_CODE_CHILD_SESSION and sets CLAUDE_CODE_FORCE_SESSION_PERSISTENCE, matching Spawn 1.3.0. Launching MARVIN from inside an agent tool call previously produced a monochrome session with no recoverable transcript.
- `marvin` is unchanged and still runs in the current shell and window, forwarding all arguments to claude.
- PowerShellVersion raised to 7.0 to match the rest of the repo and the pwsh-only launch path.

Version 1.0.0
- Initial module release
- marvin command to launch MARVIN via Claude Code
- mcode command to open MARVIN in IDE
- ASCII banner on launch
'@
        }
    }
}
