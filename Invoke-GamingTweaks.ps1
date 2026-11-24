#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Dark-themed Windows Forms desktop GUI for the 105-tweak PC & gaming optimization list.
.DESCRIPTION
    Displays all 105 tweaks (#1-#105) in a styled ListView with category filters,
    colored dark UI controls, and Apply / Rollback execution for scriptable tweaks.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Color Palette (Dark HUD) ---
$BgDark     = [System.Drawing.Color]::FromArgb(13, 17, 26)
$BgPanel    = [System.Drawing.Color]::FromArgb(20, 27, 41)
$BgInput    = [System.Drawing.Color]::FromArgb(10, 13, 20)
$FgLight    = [System.Drawing.Color]::FromArgb(226, 232, 240)
$FgMuted    = [System.Drawing.Color]::FromArgb(148, 163, 184)
$AccentCyan = [System.Drawing.Color]::FromArgb(0, 212, 255)
$AccentGrn  = [System.Drawing.Color]::FromArgb(16, 185, 129)
$AccentAmb  = [System.Drawing.Color]::FromArgb(245, 158, 11)
$BtnDark    = [System.Drawing.Color]::FromArgb(30, 41, 59)

$FontTitle  = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$FontUiBold = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$FontUi     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
$FontMono   = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Regular)

# Scriptable IDs supported for automated Apply / Rollback
$ScriptableIds = @(2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 22, 24, 26, 27, 29, 30, 58, 59, 60, 89, 103)

# All 105 Tweaks (#1 - #105)
$AllTweaks = @(
    @{ Id = 1;   Cat = "System";   Title = "Disable Unneeded Startup Apps (Task Manager)" }
    @{ Id = 2;   Cat = "System";   Title = "Unlock & Activate Ultimate Performance Power Plan" }
    @{ Id = 3;   Cat = "System";   Title = "Restrict Background App Activity" }
    @{ Id = 4;   Cat = "System";   Title = "Reduce Optional Diagnostic Telemetry" }
    @{ Id = 5;   Cat = "System";   Title = "Enable Storage Sense" }
    @{ Id = 6;   Cat = "System";   Title = "Tune Visual Effects for Responsiveness" }
    @{ Id = 7;   Cat = "System";   Title = "Disable Update Delivery Optimization Sharing" }
    @{ Id = 8;   Cat = "System";   Title = "Enable Hardware-Accelerated GPU Scheduling (HAGS)" }
    @{ Id = 9;   Cat = "System";   Title = "Disable Fast Startup for Clean Kernel Boots" }
    @{ Id = 10;  Cat = "System";   Title = "Disable Hibernation (hiberfil.sys)" }
    @{ Id = 11;  Cat = "System";   Title = "Create a God Mode Control Folder on Desktop" }
    @{ Id = 12;  Cat = "System";   Title = "Restore Classic Right-Click Context Menu (Win 11)" }
    @{ Id = 13;  Cat = "System";   Title = "Disable Lock Screen Tips & Ads" }
    @{ Id = 14;  Cat = "System";   Title = "Turn Off Transparency Effects" }
    @{ Id = 15;  Cat = "System";   Title = "Disable Sticky Keys & Filter Keys Prompts" }
    @{ Id = 16;  Cat = "System";   Title = "Enable Clipboard History (Win + V)" }
    @{ Id = 17;  Cat = "System";   Title = "Set Windows Update Active Hours (8 AM - 11 PM)" }
    @{ Id = 18;  Cat = "System";   Title = "Disable Xbox Game Bar & Background Capture" }
    @{ Id = 19;  Cat = "System";   Title = "Disable Core Isolation (Memory Integrity)" }
    @{ Id = 20;  Cat = "System";   Title = "Check Virtualization-Based Security (VBS) Impact" }
    @{ Id = 21;  Cat = "System";   Title = "Audit Scheduled Tasks" }
    @{ Id = 22;  Cat = "System";   Title = "Disable Remote Assistance" }
    @{ Id = 23;  Cat = "System";   Title = "Clean Up Old Driver Packages" }
    @{ Id = 24;  Cat = "System";   Title = "Run SSD TRIM Optimization on C:" }
    @{ Id = 25;  Cat = "System";   Title = "Configure Custom Pagefile Size" }
    @{ Id = 26;  Cat = "System";   Title = "Disable Suggested Content in Start & Settings" }
    @{ Id = 27;  Cat = "System";   Title = "Batch Update Apps via winget" }
    @{ Id = 28;  Cat = "System";   Title = "Uninstall Pre-installed Bloatware" }
    @{ Id = 29;  Cat = "System";   Title = "Turn Off File Explorer Recent/Frequent Clutter" }
    @{ Id = 30;  Cat = "System";   Title = "Show File Extensions & Hidden Items" }

    @{ Id = 31;  Cat = "Gaming";   Title = "Enable XMP (Intel) or EXPO (AMD) in BIOS" }
    @{ Id = 32;  Cat = "Gaming";   Title = "Enable Resizable BAR / Smart Access Memory" }
    @{ Id = 33;  Cat = "Gaming";   Title = "Set Refresh Rate to Native Maximum" }
    @{ Id = 34;  Cat = "Gaming";   Title = "Set GPU Power Mode to Prefer Maximum Performance" }
    @{ Id = 35;  Cat = "Gaming";   Title = "Configure Low Latency / Radeon Anti-Lag" }
    @{ Id = 36;  Cat = "Gaming";   Title = "Cap Frame Rate ~3 FPS Below Refresh Rate" }
    @{ Id = 37;  Cat = "Gaming";   Title = "Prefer Exclusive Fullscreen or Borderless Flip Model" }
    @{ Id = 38;  Cat = "Gaming";   Title = "Disable Fullscreen Optimizations Per App" }
    @{ Id = 39;  Cat = "Gaming";   Title = "Override High DPI Scaling Behavior" }
    @{ Id = 40;  Cat = "Gaming";   Title = "Tune Texture Filtering Quality" }
    @{ Id = 41;  Cat = "Gaming";   Title = "Expand Shader Cache Size" }
    @{ Id = 42;  Cat = "Gaming";   Title = "Undervolt Your GPU" }
    @{ Id = 43;  Cat = "Gaming";   Title = "Undervolt or Tune CPU Curve Optimizer" }
    @{ Id = 44;  Cat = "Gaming";   Title = "Set Custom Fan Curves" }
    @{ Id = 45;  Cat = "Gaming";   Title = "Disable Hardware Acceleration in Background Apps" }
    @{ Id = 46;  Cat = "Gaming";   Title = "Disable Unneeded Game Overlays" }
    @{ Id = 47;  Cat = "Gaming";   Title = "Drop High-Cost Settings First" }
    @{ Id = 48;  Cat = "Gaming";   Title = "Use Upscaling Wisely (DLSS / FSR / XeSS)" }
    @{ Id = 49;  Cat = "Gaming";   Title = "Monitor Frame Times, Not Just Average FPS" }
    @{ Id = 50;  Cat = "Gaming";   Title = "Lock Background Downloads During Play" }
    @{ Id = 51;  Cat = "Gaming";   Title = "Separate Game Library onto Fast NVMe SSD" }
    @{ Id = 52;  Cat = "Gaming";   Title = "Keep ~15-20% Free Space on SSDs" }
    @{ Id = 53;  Cat = "Gaming";   Title = "Verify PCIe Slot & Link Speed" }
    @{ Id = 54;  Cat = "Gaming";   Title = "Reset Overclocks When Debugging Crashes" }
    @{ Id = 55;  Cat = "Gaming";   Title = "Update Chipset & GPU Drivers Cleanly" }

    @{ Id = 56;  Cat = "Network";  Title = "Use Wired Ethernet Over Wi-Fi for Low Latency" }
    @{ Id = 57;  Cat = "Network";  Title = "Switch to the 5 GHz or 6 GHz Band on Wi-Fi" }
    @{ Id = 58;  Cat = "Network";  Title = "Set Fast Cloudflare DNS (1.1.1.1 / 1.0.0.1)" }
    @{ Id = 59;  Cat = "Network";  Title = "Flush Local DNS Resolver Cache" }
    @{ Id = 60;  Cat = "Network";  Title = "Reset Winsock & TCP/IP Network Stack" }
    @{ Id = 61;  Cat = "Network";  Title = "Disable Wi-Fi Adapter Power Saving" }
    @{ Id = 62;  Cat = "Network";  Title = "Install a Trusted Content/Ad Blocker" }
    @{ Id = 63;  Cat = "Network";  Title = "Enable Browser Memory Saver / Sleeping Tabs" }
    @{ Id = 64;  Cat = "Network";  Title = "Turn Off Background Browser Apps When Closed" }
    @{ Id = 65;  Cat = "Network";  Title = "Disable Page Preloading on Metered Connections" }
    @{ Id = 66;  Cat = "Network";  Title = "Enable HTTPS-Only / Always Use Secure Connections" }
    @{ Id = 67;  Cat = "Network";  Title = "Block Third-Party Cookies" }
    @{ Id = 68;  Cat = "Network";  Title = "Use Custom Address Bar Search Keywords" }
    @{ Id = 69;  Cat = "Network";  Title = "Pin Essential Tabs & Separate Browser Profiles" }
    @{ Id = 70;  Cat = "Network";  Title = "Master Browser Tab Shortcuts" }
    @{ Id = 71;  Cat = "Network";  Title = "Use Middle-Click to Open/Close Links & Tabs" }
    @{ Id = 72;  Cat = "Network";  Title = "Enable Reader View for Clutter-Free Reading" }
    @{ Id = 73;  Cat = "Network";  Title = "Audit & Trim Browser Extensions" }
    @{ Id = 74;  Cat = "Network";  Title = "Use a Dedicated Password Manager" }
    @{ Id = 75;  Cat = "Network";  Title = "Check Router QoS / SQM Bufferbloat" }
    @{ Id = 76;  Cat = "Network";  Title = "Verify Ethernet Link Negotiation Speed" }
    @{ Id = 77;  Cat = "Network";  Title = "Clear Corrupted Site Data for Specific Sites" }
    @{ Id = 78;  Cat = "Network";  Title = "Leave IPv6 Enabled Unless ISP Has Broken Routing" }

    @{ Id = 79;  Cat = "Workflow"; Title = "Master Win + Shift + S Screen Snipping" }
    @{ Id = 80;  Cat = "Workflow"; Title = "Install Microsoft PowerToys" }
    @{ Id = 81;  Cat = "Workflow"; Title = "Use Everything for Instant NTFS File Search" }
    @{ Id = 82;  Cat = "Workflow"; Title = "Snap Windows with Win + Z or Win + Arrow Keys" }
    @{ Id = 83;  Cat = "Workflow"; Title = "Use Virtual Desktops (Win + Ctrl + D)" }
    @{ Id = 84;  Cat = "Workflow"; Title = "Delete Whole Words with Ctrl + Backspace" }
    @{ Id = 85;  Cat = "Workflow"; Title = "Jump Across Words with Ctrl + Left/Right Arrow" }
    @{ Id = 86;  Cat = "Workflow"; Title = "Select Text Fast with Ctrl + Shift + Arrows" }
    @{ Id = 87;  Cat = "Workflow"; Title = "Use Win + . (Period) for Emoji & Symbols" }
    @{ Id = 88;  Cat = "Workflow"; Title = "Lock Your PC Instantly (Win + L)" }
    @{ Id = 89;  Cat = "Workflow"; Title = "Open Night Light Settings" }
    @{ Id = 90;  Cat = "Workflow"; Title = "Calibrate Monitor Brightness & Contrast Properly" }
    @{ Id = 91;  Cat = "Workflow"; Title = "Set Up Multi-Monitor Alignment & Scaling" }
    @{ Id = 92;  Cat = "Workflow"; Title = "Use Windows Terminal Tabs (wt.exe)" }
    @{ Id = 93;  Cat = "Workflow"; Title = "Customize PowerShell `$PROFILE" }
    @{ Id = 94;  Cat = "Workflow"; Title = "Standardize Folder Naming (YYYY-MM-DD)" }
    @{ Id = 95;  Cat = "Workflow"; Title = "Keep Desktop Icons Minimal" }
    @{ Id = 96;  Cat = "Workflow"; Title = "Use Cloud Sync Selective Folders" }
    @{ Id = 97;  Cat = "Workflow"; Title = "Follow the 3-2-1 Backup Rule" }
    @{ Id = 98;  Cat = "Workflow"; Title = "Automate Repetitive Tasks with AutoHotkey (AHK)" }
    @{ Id = 99;  Cat = "Workflow"; Title = "Use Ctrl + Shift + Esc Over Ctrl + Alt + Del" }
    @{ Id = 100; Cat = "Workflow"; Title = "Restart Instead of Only Shutting Down" }
    @{ Id = 101; Cat = "Workflow"; Title = "Dust PC Intake Filters & Heatsinks Regularly" }
    @{ Id = 102; Cat = "Workflow"; Title = "Cable-Manage Inside & Behind the Desk" }
    @{ Id = 103; Cat = "Workflow"; Title = "Create a System Restore Point" }
    @{ Id = 104; Cat = "Workflow"; Title = "Keep a Bootable Windows Recovery USB Ready" }
    @{ Id = 105; Cat = "Workflow"; Title = "Audit Installed Programs Every Few Months" }
)

function Set-RegValue {
    param (
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] $Value,
        [ValidateSet("DWord", "QWord", "String", "ExpandString", "Binary")]
        [string] $Type = "DWord"
    )
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Write-Log {
    param (
        [System.Windows.Forms.RichTextBox] $Box,
        [string] $Text,
        [System.Drawing.Color] $Color = $FgLight
    )
    $Box.SelectionStart = $Box.TextLength
    $Box.SelectionLength = 0
    $Box.SelectionColor = $Color
    $Box.AppendText("$Text`r`n")
    $Box.ScrollToCaret()
}

function Invoke-ScriptableTweak {
    param (
        [int] $Id,
        [ValidateSet("Apply", "Rollback")] [string] $Mode,
        [System.Windows.Forms.RichTextBox] $LogBox
    )

    switch ($Id) {
        2 {
            if ($Mode -eq "Apply") {
                $ultOut = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
                if ($ultOut -match "([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})") {
                    powercfg /setactive $Matches[1] | Out-Null
                    Write-Log $LogBox "[OK] #2 Activated Ultimate Performance Plan ($($Matches[1]))." $AccentGrn
                } else {
                    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null | Out-Null
                    Write-Log $LogBox "[OK] #2 Activated High Performance fallback plan." $AccentGrn
                }
            } else {
                powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null | Out-Null
                Write-Log $LogBox "[REVERT] #2 Restored Balanced power plan." $AccentAmb
            }
        }
        4 {
            $val = if ($Mode -eq "Apply") { 1 } else { 3 }
            Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #4 Diagnostic telemetry (AllowTelemetry) -> $val" $AccentCyan
        }
        5 {
            $val = if ($Mode -eq "Apply") { 1 } else { 0 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #5 Storage Sense policy -> $val" $AccentCyan
        }
        6 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IconsOnly" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value "2" -Type "String"
                Set-RegValue -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothingType" -Value 2 -Type "DWord"
                Set-RegValue -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type "String"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "1" -Type "String"
            }
            Write-Log $LogBox "[$Mode] #6 Visual effects & animations updated." $AccentCyan
        }
        7 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #7 Delivery Optimization sharing -> $val" $AccentCyan
        }
        8 {
            $val = if ($Mode -eq "Apply") { 2 } else { 1 }
            Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #8 HAGS (HwSchMode) -> $val" $AccentCyan
        }
        9 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #9 Fast Startup (HiberbootEnabled) -> $val" $AccentCyan
        }
        10 {
            if ($Mode -eq "Apply") {
                powercfg -h off | Out-Null
                Write-Log $LogBox "[OK] #10 Hibernation disabled (hiberfil.sys removed)." $AccentGrn
            } else {
                powercfg -h on | Out-Null
                Write-Log $LogBox "[REVERT] #10 Hibernation re-enabled." $AccentAmb
            }
        }
        11 {
            $godPath = "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
            if ($Mode -eq "Apply") {
                if (-not (Test-Path $godPath)) { New-Item -Path $godPath -ItemType Directory -Force | Out-Null }
                Write-Log $LogBox "[OK] #11 Created God Mode folder on Desktop." $AccentGrn
            } elseif (Test-Path $godPath) {
                Remove-Item -Path $godPath -Force -Recurse
                Write-Log $LogBox "[REVERT] #11 Removed God Mode folder from Desktop." $AccentAmb
            }
        }
        12 {
            $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
            if ($Mode -eq "Apply") {
                New-Item -Path $clsidPath -Force | Out-Null
                Set-ItemProperty -Path $clsidPath -Name "(Default)" -Value "" -Force
                Write-Log $LogBox "[OK] #12 Classic Windows 11 right-click menu enabled." $AccentGrn
            } else {
                Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log $LogBox "[REVERT] #12 Restored default Windows 11 context menu." $AccentAmb
            }
        }
        13 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value $val -Type "DWord"
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #13 Lock screen tips/ads -> $val" $AccentCyan
        }
        14 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #14 Transparency effects -> $val" $AccentCyan
        }
        15 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Type "String"
                Set-RegValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Value "122" -Type "String"
                Set-RegValue -Path "HKCU:\Control Panel\Accessibility\ToggleKeys" -Name "Flags" -Value "58" -Type "String"
            } else {
                Set-RegValue -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "510" -Type "String"
                Set-RegValue -Path "HKCU:\Control Panel\Accessibility\Keyboard Response" -Name "Flags" -Value "126" -Type "String"
            }
            Write-Log $LogBox "[$Mode] #15 Sticky/Filter Keys prompts updated." $AccentCyan
        }
        16 {
            $val = if ($Mode -eq "Apply") { 1 } else { 0 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #16 Clipboard history (Win+V) -> $val" $AccentCyan
        }
        17 {
            $endHour = if ($Mode -eq "Apply") { 23 } else { 17 }
            Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursStart" -Value 8 -Type "DWord"
            Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursEnd" -Value $endHour -Type "DWord"
            Write-Log $LogBox "[$Mode] #17 Update active hours -> 8 AM to $endHour:00." $AccentCyan
        }
        18 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -Type "DWord"
                Set-RegValue -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -Type "DWord"
            }
            Write-Log $LogBox "[$Mode] #18 Xbox Game Bar capture updated." $AccentCyan
        }
        19 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #19 Core Isolation (Memory Integrity) -> $val" $AccentAmb
        }
        22 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #22 Remote Assistance -> $val" $AccentCyan
        }
        24 {
            if ($Mode -eq "Apply") {
                Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue | Out-Null
                Write-Log $LogBox "[OK] #24 SSD TRIM completed on C:." $AccentGrn
            } else {
                Write-Log $LogBox "[INFO] #24 SSD TRIM is non-destructive (no rollback needed)." $FgMuted
            }
        }
        26 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value $val -Type "DWord"
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value $val -Type "DWord"
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #26 Suggested content / ads -> $val" $AccentCyan
        }
        27 {
            if ($Mode -eq "Apply") {
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    Write-Log $LogBox "[INFO] #27 Running winget upgrade --all..." $AccentCyan
                    Start-Process -FilePath "winget" -ArgumentList "upgrade --all --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait
                    Write-Log $LogBox "[OK] #27 winget upgrade finished." $AccentGrn
                } else {
                    Write-Log $LogBox "[WARN] #27 winget not found." $AccentAmb
                }
            } else {
                Write-Log $LogBox "[INFO] #27 winget upgrades have no automatic rollback." $FgMuted
            }
        }
        29 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Value $val -Type "DWord"
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value $val -Type "DWord"
            Write-Log $LogBox "[$Mode] #29 Explorer recent/frequent -> $val" $AccentCyan
        }
        30 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -Type "DWord"
            }
            Write-Log $LogBox "[$Mode] #30 File extensions & hidden items updated." $AccentCyan
        }
        58 {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true }
            foreach ($nic in $adapters) {
                if ($Mode -eq "Apply") {
                    Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1")
                    Write-Log $LogBox "[OK] #58 Set DNS 1.1.1.1 / 1.0.0.1 on $($nic.Name)." $AccentGrn
                } else {
                    Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ResetServerAddresses
                    Write-Log $LogBox "[REVERT] #58 Reset DNS to DHCP on $($nic.Name)." $AccentAmb
                }
            }
        }
        59 {
            if ($Mode -eq "Apply") {
                Clear-DnsClientCache
                Write-Log $LogBox "[OK] #59 Flushed local DNS cache." $AccentGrn
            } else {
                Write-Log $LogBox "[INFO] #59 DNS cache repopulates automatically." $FgMuted
            }
        }
        60 {
            if ($Mode -eq "Apply") {
                netsh int ip reset | Out-Null
                netsh winsock reset | Out-Null
                Write-Log $LogBox "[OK] #60 Reset TCP/IP & Winsock (reboot required)." $AccentGrn
            } else {
                Write-Log $LogBox "[INFO] #60 Winsock/TCP reset uses clean Windows defaults." $FgMuted
            }
        }
        89 {
            Start-Process "ms-settings:nightlight"
            Write-Log $LogBox "[$Mode] #89 Opened Night Light settings." $AccentCyan
        }
        103 {
            if ($Mode -eq "Apply") {
                Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
                try {
                    Checkpoint-Computer -Description "PC-Tweak-GUI-105" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                    Write-Log $LogBox "[OK] #103 Created System Restore Point." $AccentGrn
                } catch {
                    Write-Log $LogBox "[WARN] #103 Restore Point skipped (Windows allows 1 automatic point per 24h)." $AccentAmb
                }
            } else {
                Start-Process "rstrui.exe"
                Write-Log $LogBox "[REVERT] #103 Opened System Restore (rstrui.exe)." $AccentAmb
            }
        }
    }
}

# --- Build Styled Dark Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "APEX 105-Tweak PC Controller"
$form.Size = New-Object System.Drawing.Size(860, 640)
$form.MinimumSize = New-Object System.Drawing.Size(760, 540)
$form.StartPosition = "CenterScreen"
$form.BackColor = $BgDark
$form.ForeColor = $FgLight
$form.Font = $FontUi

$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "APEX // 105-TWEAK OPTIMIZATION CONTROLLER (#1 - #105)"
$lblHeader.Location = New-Object System.Drawing.Point(16, 12)
$lblHeader.Size = New-Object System.Drawing.Size(560, 26)
$lblHeader.Font = $FontTitle
$lblHeader.ForeColor = $AccentCyan

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "All 105 tweaks listed in order. Checkboxes apply to PS1-automated tweaks; manual/BIOS/shortcut items are marked [Manual]."
$lblSub.Location = New-Object System.Drawing.Point(16, 38)
$lblSub.Size = New-Object System.Drawing.Size(810, 20)
$lblSub.ForeColor = $FgMuted

# Category Filter Buttons
$script:CurrentFilter = "All"
$filterPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$filterPanel.Location = New-Object System.Drawing.Point(16, 64)
$filterPanel.Size = New-Object System.Drawing.Size(816, 34)
$filterPanel.BackColor = $BgDark

$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(16, 104)
$listView.Size = New-Object System.Drawing.Size(816, 295)
$listView.View = [System.Windows.Forms.View]::Details
$listView.FullRowSelect = $true
$listView.CheckBoxes = $true
$listView.GridLines = $true
$listView.BackColor = $BgPanel
$listView.ForeColor = $FgLight
$listView.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$listView.Font = $FontUi

[void]$listView.Columns.Add("#", 55)
[void]$listView.Columns.Add("Category", 95)
[void]$listView.Columns.Add("Mode", 85)
[void]$listView.Columns.Add("Tweak Description", 560)

function Populate-ListView {
    param ([string] $CategoryFilter)
    $script:CurrentFilter = $CategoryFilter
    $listView.BeginUpdate()
    $listView.Items.Clear()

    foreach ($t in $AllTweaks) {
        if ($CategoryFilter -ne "All" -and $t.Cat -ne $CategoryFilter) { continue }
        $isScriptable = ($ScriptableIds -contains $t.Id)
        $modeText = if ($isScriptable) { "PS1 Auto" } else { "Manual" }

        $item = New-Object System.Windows.Forms.ListViewItem("#$($t.Id)")
        [void]$item.SubItems.Add($t.Cat)
        [void]$item.SubItems.Add($modeText)
        [void]$item.SubItems.Add($t.Title)
        $item.Tag = $t.Id
        $item.BackColor = $BgPanel
        $item.ForeColor = if ($isScriptable) { $FgLight } else { $FgMuted }
        $item.Checked = ($isScriptable -and ($t.Id -in @(2, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15, 17, 18, 22, 24, 26, 29, 30, 58, 59, 103)))

        [void]$listView.Items.Add($item)
    }

    $listView.EndUpdate()
}

foreach ($catName in @("All", "System", "Gaming", "Network", "Workflow")) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $catName
    $b.Size = New-Object System.Drawing.Size(92, 28)
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.BackColor = $BtnDark
    $b.ForeColor = $FgLight
    $b.Font = $FontUiBold
    $b.FlatAppearance.BorderColor = $AccentCyan
    $b.FlatAppearance.BorderSize = 1
    $b.Tag = $catName
    $b.Add_Click({
        Populate-ListView -CategoryFilter $this.Tag
    })
    [void]$filterPanel.Controls.Add($b)
}

function New-StyledButton {
    param ([string] $Text, [int] $X, [int] $Y, [int] $W, [System.Drawing.Color] $BorderCol, [System.Drawing.Color] $TextCol)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point($X, $Y)
    $btn.Size = New-Object System.Drawing.Size($W, 34)
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.BackColor = $BtnDark
    $btn.ForeColor = $TextCol
    $btn.Font = $FontUiBold
    $btn.FlatAppearance.BorderColor = $BorderCol
    $btn.FlatAppearance.BorderSize = 1
    return $btn
}

$btnApply    = New-StyledButton "Apply Checked"    16  410 135 $AccentCyan $AccentCyan
$btnRollback = New-StyledButton "Rollback Checked" 159 410 145 $AccentAmb  $AccentAmb
$btnCheckAll = New-StyledButton "Check Auto"     312 410 110 $AccentGrn  $AccentGrn
$btnUncheck  = New-StyledButton "Uncheck All"    430 410 115 $FgMuted    $FgLight
$btnClearLog = New-StyledButton "Clear Log"      553 410 100 $FgMuted    $FgMuted

$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(16, 454)
$logBox.Size = New-Object System.Drawing.Size(816, 134)
$logBox.BackColor = $BgInput
$logBox.ForeColor = $FgLight
$logBox.Font = $FontMono
$logBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$logBox.ReadOnly = $true

function Get-CheckedScriptableIds {
    $ids = @()
    foreach ($item in $listView.Items) {
        if ($item.Checked) {
            $tweakId = [int]$item.Tag
            if ($ScriptableIds -contains $tweakId) {
                $ids += $tweakId
            }
        }
    }
    return ($ids | Sort-Object -Unique)
}

$btnApply.Add_Click({
    $ids = Get-CheckedScriptableIds
    Write-Log $logBox "=== Applying $($ids.Count) automated tweak(s) ===" $AccentCyan
    foreach ($id in $ids) {
        Invoke-ScriptableTweak -Id $id -Mode "Apply" -LogBox $logBox
    }
    Write-Log $LogBox "=== Apply complete. Restart your PC for full effect. ===" $AccentGrn
})

$btnRollback.Add_Click({
    $ids = Get-CheckedScriptableIds
    Write-Log $LogBox "=== Rolling back $($ids.Count) automated tweak(s) ===" $AccentAmb
    foreach ($id in $ids) {
        Invoke-ScriptableTweak -Id $id -Mode "Rollback" -LogBox $logBox
    }
    Write-Log $LogBox "=== Rollback complete. Restart your PC if needed. ===" $AccentAmb
})

$btnCheckAll.Add_Click({
    foreach ($item in $listView.Items) {
        $item.Checked = ($ScriptableIds -contains ([int]$item.Tag))
    }
})

$btnUncheck.Add_Click({
    foreach ($item in $listView.Items) {
        $item.Checked = $false
    }
})

$btnClearLog.Add_Click({
    $logBox.Clear()
})

Populate-ListView -CategoryFilter "All"
Write-Log $logBox "Loaded all 105 tweaks (#1-#105). Select PS1 Auto tweaks and click Apply Checked or Rollback Checked." $AccentCyan

$form.Controls.AddRange(@($lblHeader, $lblSub, $filterPanel, $listView, $btnApply, $btnRollback, $btnCheckAll, $btnUncheck, $btnClearLog, $logBox))
[void]$form.ShowDialog()