@{
    RootModule = 'Rocky.psm1'

    ModuleVersion = '1.0.0'

    GUID = 'a7f3e1b2-5d8c-4f6a-9e2d-1b4c7a8f3e5d'

    Author = 'Travis Haley'

    CompanyName = 'Personal'

    Copyright = '(c) 2026 Travis Haley. All rights reserved.'

    Description = 'ROCKY - Skunkworks Lab Partner. Curious Eridian engineer for tinkering projects, powered by Claude Code.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @('rocky', 'Show-RockyBanner')

    CmdletsToExport = @()

    VariablesToExport = @()

    AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('AI', 'Claude', 'Skunkworks', 'Assistant', 'ROCKY')
            ReleaseNotes = @'
Version 1.0.0
- Initial module release
- rocky command to launch ROCKY via Claude Code
- Rainbow ASCII banner on launch
'@
        }
    }
}
