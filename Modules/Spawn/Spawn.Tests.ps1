$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $here 'Spawn.psd1') -Force

Describe 'Start-AgentSession' {
    BeforeEach {
        $script:hf = Join-Path $TestDrive 'topic--plan.md'
        Set-Content -LiteralPath $script:hf -Value '# handoff'
        $script:wd = $TestDrive
    }

    It 'builds a wt.exe command with the named window, model, and fixed prompt' {
        $out = Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir $script:wd -DryRun
        $out | Should -Match 'wt\.exe -w agent-relay new-tab'
        $out | Should -Match 'claude --model sonnet'
        $out | Should -Match ([regex]::Escape("Read $script:hf and do what it says."))
    }

    It 'omits skip-permissions by default' {
        $out = Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir $script:wd -DryRun
        $out | Should -Not -Match '--dangerously-skip-permissions'
    }

    It 'includes skip-permissions when requested' {
        $out = Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir $script:wd -SkipPermissions -DryRun
        $out | Should -Match '--dangerously-skip-permissions'
    }

    It 'includes remote-control by default, named after the title' {
        $out = Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir $script:wd -DryRun
        $out | Should -Match '--remote-control topic--plan'
    }

    It 'omits remote-control when -NoRemoteControl is passed' {
        $out = Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir $script:wd -NoRemoteControl -DryRun
        $out | Should -Not -Match '--remote-control'
    }

    It 'names the remote-control session after the title, before the prompt' {
        $out = Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir $script:wd -DryRun
        $out | Should -Match "--remote-control topic--plan 'Read "
    }

    It 'sanitizes the remote-control name so quoting cannot break' {
        $out = Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir $script:wd -Title "it's a plan" -DryRun
        $out | Should -Match '--remote-control it-s-a-plan '
    }

    It 'defaults the title to the handoff base name' {
        $out = Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir $script:wd -DryRun
        $out | Should -Match '--title topic--plan'
    }

    It 'quotes a space-containing WorkDir in the DryRun display' {
        $spaceDir = Join-Path $TestDrive 'work dir'
        New-Item -ItemType Directory -Path $spaceDir | Out-Null
        $spaceFile = Join-Path $spaceDir 'topic--plan.md'
        Set-Content -LiteralPath $spaceFile -Value '# h'
        $out = Start-AgentSession -HandoffFile $spaceFile -Model sonnet -WorkDir $spaceDir -DryRun
        $out | Should -Match ([regex]::Escape('"' + $spaceDir + '"'))
    }

    It 'resolves the spawn alias to the function' {
        (Get-Alias spawn).Definition | Should -Be 'Start-AgentSession'
    }

    It 'throws when the handoff file is missing' {
        { Start-AgentSession -HandoffFile (Join-Path $TestDrive 'nope.md') -Model sonnet -WorkDir $script:wd -DryRun } | Should -Throw
    }

    It 'throws when the work dir is missing' {
        { Start-AgentSession -HandoffFile $script:hf -Model sonnet -WorkDir (Join-Path $TestDrive 'nodir') -DryRun } | Should -Throw
    }
}
