# Decorative startup banner -- relies on cursor positioning. Skip it unless the
# host actually supports that. Non-interactive, redirected, CI, or a VSCode
# terminal caught mid-init otherwise throw a flood of "handle is invalid".
$bannerCanRender = $false
try {
    if ($Host.Name -eq 'ConsoleHost' -and -not [System.Console]::IsOutputRedirected) {
        $null = [System.Console]::WindowWidth
        $null = [System.Console]::CursorTop
        $bannerCanRender = $true
    }
} catch { $bannerCanRender = $false }
if (-not $bannerCanRender) { return }

Write-Host "Getting system information..."

$computer   = Get-CimInstance Win32_ComputerSystem
$os         = Get-CimInstance Win32_OperatingSystem
$processor  = Get-CimInstance Win32_Processor
$gpu        = Get-CimInstance Win32_VideoController | Select-Object -First 1
$network    = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object IPAddress
$uptime     = (Get-Date) - $os.LastBootUpTime
$ipAddresses = ($network | ForEach-Object { $_.IPAddress[0] }) -join ", "

$info = @(
    "Computer: ",  "$($env:COMPUTERNAME) - $($computer.Model), $($computer.Manufacturer)",
    "Uptime:   ",  "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s",
    "OS:       ",  "$($os.Caption) $($os.OSArchitecture)",
    "Kernel:   ",  "$($os.Version)",
    "CPU:      ",  "$($processor.Name)",
    "GPU:      ",  "$($gpu.Name)",
    "Memory:   ",  "$([math]::Truncate($os.FreePhysicalMemory / 1KB)) MB / $([math]::Truncate($computer.TotalPhysicalMemory / 1MB)) MB",
    "Network:  ",  "$ipAddresses",
    "Shell:    ",  "PowerShell v$($Host.Version)"
)

Clear-Host

function WriteTo-Pos (
    [string] $str,
    [int]    $x   = 0,
    [int]    $y   = 0,
    [string] $bgc = [console]::BackgroundColor,
    [string] $fgc = [console]::ForegroundColor
) {
    try {
        if ($x -ge 0 -and $y -ge 0 -and $x -le [Console]::WindowWidth -and $y -le [Console]::WindowHeight) {
            $saveY = [console]::CursorTop
            $offY  = [console]::WindowTop
            [console]::SetCursorPosition($x, $offY + $y)
            Write-Host -Object $str -BackgroundColor $bgc -ForegroundColor $fgc -NoNewline
            [console]::SetCursorPosition(0, $saveY)
        }
    } catch { }  # host lost its console handle mid-render; skip this cell
}

# Print ASCII logo
if ($Host.UI.RawUI.MaxWindowSize.Width -ge 40) {
    if ($computer.Manufacturer -eq "Apple Inc.") {
        Get-Content "$PSScriptRoot\..\Logos\apple.txt"
    } else {
        Get-Content "$PSScriptRoot\..\Logos\flag.ans" -Encoding Unicode
    }
}

# Print system information
if ($Host.UI.RawUI.MaxWindowSize.Width -ge 80) {
    $y = 5; $x = 45
    for ($i = 0; $i -lt $info.Length; $i += 2) {
        $label = $info[$i]
        $value = $info[$i + 1]
        $maxW  = $Host.UI.RawUI.MaxWindowSize.Width - $x - $label.Length
        if ($maxW -lt 0) { $maxW = 0 }
        if ($value.Length -gt $maxW) { $value = $value.Substring(0, $maxW) }
        WriteTo-Pos -str $label -x $x -y $y -fgc "Cyan"
        $x += $label.Length
        WriteTo-Pos -str $value -x $x -y $y -fgc "White"
        $x = 45
        $y++
    }
}

Write-Host
