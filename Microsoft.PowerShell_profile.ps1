# Guard: don't load in NuGet console
if (Get-Module NuGet) { return }

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
$MaximumHistoryCount = 512
$FormatEnumerationLimit = 100

# ---------------------------------------------------------------------------
# Path
# ---------------------------------------------------------------------------
$vsPath = 'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\'
if ((Test-Path $vsPath) -and (-not $env:Path.Contains($vsPath))) {
    $env:Path += ';' + $vsPath
}

# fnm - Fast Node Manager
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# ---------------------------------------------------------------------------
# Scripts
# ---------------------------------------------------------------------------
$scriptsPath = Join-Path $PSScriptRoot "Scripts"
if (Test-Path $scriptsPath) {
    Resolve-Path "$scriptsPath\*.ps1" |
        Where-Object { -not $_.ProviderPath.Contains(".Tests.") } |
        ForEach-Object { . $_.ProviderPath }
}

# ---------------------------------------------------------------------------
# Modules
# ---------------------------------------------------------------------------
if ($host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine
    Set-PSReadLineOption -MaximumHistoryCount 4000
    Set-PSReadLineOption -ShowToolTips
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Shift+Tab' -Function Complete
}

# fzf fuzzy finder (install: winget install junegunn.fzf; Install-Module PSFzf)
if (Get-Module -ListAvailable PSFzf -ErrorAction SilentlyContinue) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+T' -PSReadlineChordReverseHistory 'Ctrl+R'
    Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock { Invoke-FuzzyHistory }
    Set-PSReadLineKeyHandler -Key Ctrl+t -ScriptBlock { Invoke-FuzzySetLocation }
}

# Git (install: Install-Module Posh-Git)
Import-Module Posh-Git -ErrorAction SilentlyContinue

# Expected modules - warn (don't silently swallow) if one goes missing or fails.
foreach ($mod in @('PSColor', 'Write-Ascii', 'StreamUtils', 'StringUtils', 'Profile', 'AICommand')) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Warning "Profile module '$mod' not found -- skipping. Restore it or run: Install-Module $mod"
        continue
    }
    try {
        Import-Module $mod -ErrorAction Stop
    } catch {
        Write-Warning "Profile module '$mod' failed to import: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
Set-Alias unset Remove-Variable
Set-Alias mo    Measure-Object
Set-Alias eval  Invoke-Expression
Set-Alias n     code
Set-Alias vi    code
Set-Alias krak  kraken

if (Get-Command devenv.exe -ErrorAction SilentlyContinue) {
    Set-Alias vs devenv.exe
}

function which($cmd) { (Get-Command $cmd).Definition }

Remove-Item alias:ls -ErrorAction SilentlyContinue
function ls { Get-ChildItem -Force @args }

# ---------------------------------------------------------------------------
# Prompt
# ---------------------------------------------------------------------------
Set-Variable -Scope Global WindowTitle ''

function prompt {
    $pathObj = Get-Location
    $path    = $pathObj.Path
    $drive   = $pathObj.Drive.Name

    if (-not $drive) {
        if ($path.Contains('::')) { $path = $pathObj.ProviderPath }
        if ($path -match "^\\\\([^\\]+)\\") { $drive = $matches[1] }
    }

    $currentUser    = [Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdminProcess = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $adminHeader    = if ($isAdminProcess) { 'Administrator: ' } else { '' }

    if (-not (Get-Module NuGet)) {
        $title = "$adminHeader$path"
        if ($WindowTitle) { $title += " - $WindowTitle" }
        try { $host.ui.rawUi.windowTitle = $title } catch { }
        $path = [IO.Path]::GetFileName($path)
        if (-not $path) { $path = '\' }
    }

    if ($NestedPromptLevel) {
        Write-Host -NoNewline -ForegroundColor Green "$NestedPromptLevel-"
    }

    $h           = @(Get-History)
    $nextCommand = if ($h.Count -gt 0) { $h[-1].Id + 1 } else { 1 }
    Write-Host -NoNewline -ForegroundColor Red "${nextCommand}|"
    Write-Host -NoNewline -ForegroundColor Cyan "${drive}"
    Write-Host -NoNewline -ForegroundColor White ":${path}"

    if (Get-Command Write-VcsStatus -ErrorAction SilentlyContinue) {
        $realExit = $LASTEXITCODE
        Write-VcsStatus
        $global:LASTEXITCODE = $realExit
    }

    try {
        $txtRight  = "[$(Get-Date -Format 'HH:mm:ss')]`n"
        $startposx = $Host.UI.RawUI.WindowSize.Width - $txtRight.Length
        $startposy = $Host.UI.RawUI.CursorPosition.Y
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates $startposx, $startposy
        $host.UI.RawUI.ForegroundColor = 'White'
        $Host.UI.Write($txtRight)
    } catch {
        Write-Host ''  # no cursor positioning available; just end the prompt line
    }

    return '>'
}

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
function Start-NewScope {
    param($Prompt = $null)
    Write-Host "Starting New Scope"
    if ($null -ne $Prompt) {
        if ($Prompt -is [ScriptBlock]) {
            $null = New-Item function:Prompt -Value $Prompt -Force
        } else {
            function Prompt { "$Prompt" }
        }
    }
    $host.EnterNestedPrompt()
}

function Restart { shutdown /r /t 1 }

function kraken {
    $curpath = (Get-Location).ProviderPath
    $logf    = "$env:TEMP\krakstart.log"
    $exe     = Get-Item "$env:LOCALAPPDATA\gitkraken\app-*\gitkraken.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1
    if ($exe) {
        Start-Process -FilePath $exe -ArgumentList "--path $curpath" -RedirectStandardOutput $logf
    } else {
        Write-Warning "GitKraken not found"
    }
}

# ---------------------------------------------------------------------------
# Docker (native engine in WSL2 / Ubuntu) -- forward CLI from PowerShell
# ---------------------------------------------------------------------------
# `docker compose ...` rides along for free (compose is a docker subcommand).
function docker     { wsl.exe -d Ubuntu docker @args }
function lazydocker { wsl.exe -d Ubuntu lazydocker @args }
Set-Alias lzd lazydocker

# Tapestry CLI -- runs the NATIVE WSL/Ubuntu install, not the Windows fnm one.
# The engine is a Docker container on the WSL daemon and bind-mounts the project
# dir, so the CLI must run inside WSL with Linux (/mnt/...) paths. This forwards
# from PowerShell, mapping the current Windows dir to its /mnt path and pinning a
# clean PATH (nvm node + system bins) so `node` and `docker` both resolve.
function tapestry {
    $nodeBin   = '/home/mallek/.nvm/versions/node/v24.16.0/bin'
    $cleanPath = "${nodeBin}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    $p         = $PWD.ProviderPath   # e.g. D:\Skunkworks\legends-forgotten
    $wslCwd    = '/mnt/' + $p.Substring(0,1).ToLower() + ($p.Substring(2) -replace '\\','/')
    wsl.exe -d Ubuntu --cd "$wslCwd" -e env "PATH=$cleanPath" tapestry @args
}

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
Remove-Variable vsPath -ErrorAction SilentlyContinue
