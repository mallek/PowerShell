@{
    RootModule = 'Marvin.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'b4e2f8a1-3c7d-4a9e-8f1b-6d5c2e9a7b4f'
    Author = 'Travis Haley'
    CompanyName = 'Personal'
    Copyright = '(c) 2026 Travis Haley. All rights reserved.'
    Description = 'MARVIN - Manages Appointments, Reads Various Important Notifications. AI Chief of Staff powered by Claude Code.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('marvin', 'mcode', 'Show-MarvinBanner')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('AI', 'Claude', 'Productivity', 'Assistant', 'MARVIN')
            ReleaseNotes = @'
Version 1.0.0
- Initial module release
- marvin command to launch MARVIN via Claude Code
- mcode command to open MARVIN in IDE
- ASCII banner on launch
'@
        }
    }
}
