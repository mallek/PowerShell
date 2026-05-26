# PowerShell

PowerShell **7+** profile, modules, and scripts. The successor to
[mallek/WindowsPowerShell](https://github.com/mallek/WindowsPowerShell) after the
Windows PowerShell 5 → 7 migration.

This repo is the full contents of `Documents\PowerShell` — clone it there and go.

## Install

```powershell
git clone git@github.com:mallek/PowerShell.git $HOME\Documents\PowerShell
```

Open a new PowerShell 7 session and enjoy. The profile loads automatically.

## Prerequisites

These are referenced by the profile; install whatever you use:

- **PowerShell 7+** (`winget install Microsoft.PowerShell`)
- **fnm** — Fast Node Manager, for `node` version switching (`winget install Schniz.fnm`)
- **fzf** — fuzzy finder, powers the bundled PSFzf bindings (`winget install junegunn.fzf`)
- **git** — for posh-git status and the git aliases in `Scripts/Posh-Git-Alias.ps1`

## Layout

| Path | What |
|------|------|
| `Microsoft.PowerShell_profile.ps1` | The profile — path, modules, prompt, aliases, Docker/Tapestry WSL forwarding |
| `Modules/` | Vendored modules (PSColor, Write-Ascii, StreamUtils, StringUtils, Profile, Rocky, posh-git, PSFzf) — frozen at known-good versions |
| `Scripts/` | Dot-sourced at startup: Banner (system info), Get-DiskFree, Get-Hosts, git aliases, `sudo`/`touch` helpers |
| `Logos/` | ASCII art used by `Banner.ps1` |

## Notes

- Modules are **vendored deliberately** (not installed from the gallery) so this is a
  reproducible snapshot — the exact thing that would have prevented a painful migration
  where modules went missing.
- `Banner.ps1` and the prompt degrade gracefully (no errors) in non-interactive,
  redirected, or headless hosts.
- The expected-module loop in the profile **warns** if a module goes missing instead of
  silently swallowing it.
