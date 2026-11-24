#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Applies or rolls back automated Windows, gaming, and network tweaks from the 105-Tweak HUD.
.DESCRIPTION
    Supports -Mode Apply or -Mode Rollback, preset profiles (-Preset Esports|PowerUser|Safe|All),
    and automatic System Restore Point creation (-CreateRestorePoint).
.EXAMPLE
    .\Invoke-Optimization105.ps1 -Preset Esports -CreateRestorePoint
.EXAMPLE
    .\Invoke-Optimization105.ps1 -Mode Rollback -Preset Esports
#>

[CmdletBinding()]
param (
    [ValidateSet("Apply", "Rollback")]
    [string] $Mode = "Apply",

    [ValidateSet("Esports", "PowerUser", "Safe", "All")]
    [string] $Preset = "Esports",

    [string[]] $IncludeTweaks = @(),

    [switch] $CreateRestorePoint
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

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
    Write-Host "[OK] $Path -> $Name = $Value" -ForegroundColor Green
}

$Presets = @{
    Esports   = @(2, 4, 6, 7, 8, 9, 12, 13, 14, 15, 17, 18, 22, 24, 26, 29, 30, 58, 59, 103)
    PowerUser = @(4, 5, 6, 7, 8, 11, 12, 13, 15, 16, 17, 22, 24, 26, 27, 29, 30, 58, 59, 89, 103)
    Safe      = @(4, 5, 7, 13, 15, 16, 17, 18, 22, 26, 29, 30, 59, 103)
    All       = @(2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 22, 24, 26, 27, 29, 30, 58, 59, 60, 89, 103)
}

$SelectedTweaks = if ($IncludeTweaks.Count -gt 0) {
    $IncludeTweaks | Sort-Object -Unique
} else {
    $Presets[$Preset] | Sort-Object -Unique
}

if ($Mode -eq "Apply" -and $CreateRestorePoint) {
    Write-Host "=== [Safety] Creating Windows System Restore Point ===" -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Pre-Optimization-HUD-105" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[OK] System Restore Point created." -ForegroundColor Green
    } catch {
        Write-Warning "Skipped Restore Point (Windows limits automatic checkpoints to once per 24 hours)."
    }
}

foreach ($tweak in $SelectedTweaks) {
    switch ($tweak) {
        2 {
            if ($Mode -eq "Apply") {
                # [#2] Unlock & Activate Ultimate Performance Power Plan
                $ultOut = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
                if ($ultOut -match "([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})") {
                    powercfg /setactive $Matches[1]
                    Write-Host "[OK] Activated Ultimate Performance Plan ($($Matches[1]))" -ForegroundColor Green
                } else {
                    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
                    Write-Host "[OK] Activated High Performance fallback plan" -ForegroundColor Green
                }
            } else {
                powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
                Write-Host "[REVERT] Restored Balanced power plan" -ForegroundColor Yellow
            }
        }
        4 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 1 -Type "DWord"
            } else {
                Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 3 -Type "DWord"
            }
        }
        5 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type "DWord"
            }
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
        }
        7 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Type "DWord"
            } else {
                Set-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 1 -Type "DWord"
            }
        }
        8 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type "DWord"
            } else {
                Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 1 -Type "DWord"
            }
        }
        9 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type "DWord"
            } else {
                Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 1 -Type "DWord"
            }
        }
        10 {
            if ($Mode -eq "Apply") {
                powercfg -h off
                Write-Host "[OK] Hibernation disabled and hiberfil.sys removed." -ForegroundColor Green
            } else {
                powercfg -h on
                Write-Host "[REVERT] Hibernation re-enabled." -ForegroundColor Yellow
            }
        }
        11 {
            $godPath = "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
            if ($Mode -eq "Apply") {
                if (-not (Test-Path $godPath)) {
                    New-Item -Path $godPath -ItemType Directory -Force | Out-Null
                }
                Write-Host "[OK] Created God Mode folder on Desktop." -ForegroundColor Green
            } elseif (Test-Path $godPath) {
                Remove-Item -Path $godPath -Force -Recurse
                Write-Host "[REVERT] Removed God Mode folder." -ForegroundColor Yellow
            }
        }
        12 {
            $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
            if ($Mode -eq "Apply") {
                New-Item -Path $clsidPath -Force | Out-Null
                Set-ItemProperty -Path $clsidPath -Name "(Default)" -Value "" -Force
                Write-Host "[OK] Classic context menu enabled (restart Explorer to apply immediately)." -ForegroundColor Green
            } else {
                Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "[REVERT] Restored default Windows 11 context menu." -ForegroundColor Yellow
            }
        }
        13 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 0 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 1 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value 1 -Type "DWord"
            }
        }
        14 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1 -Type "DWord"
            }
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
        }
        16 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 1 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 0 -Type "DWord"
            }
        }
        17 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursStart" -Value 8 -Type "DWord"
                Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursEnd" -Value 23 -Type "DWord"
            } else {
                Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursStart" -Value 8 -Type "DWord"
                Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursEnd" -Value 17 -Type "DWord"
            }
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
        }
        19 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 0 -Type "DWord"
            } else {
                Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value 1 -Type "DWord"
            }
        }
        22 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 0 -Type "DWord"
            } else {
                Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 1 -Type "DWord"
            }
        }
        24 {
            if ($Mode -eq "Apply") {
                Optimize-Volume -DriveLetter C -ReTrim -Verbose
                Write-Host "[OK] SSD TRIM optimization completed on C:." -ForegroundColor Green
            } else {
                Write-Host "[INFO] [#24] SSD TRIM is a non-destructive maintenance step (no rollback needed)." -ForegroundColor Yellow
            }
        }
        26 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value 0 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 1 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 1 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value 1 -Type "DWord"
            }
        }
        27 {
            if ($Mode -eq "Apply") {
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    winget upgrade --all --accept-source-agreements --accept-package-agreements
                } else {
                    Write-Warning "winget not detected on this system."
                }
            } else {
                Write-Host "[INFO] [#27] winget upgrades do not have an automatic registry rollback." -ForegroundColor Yellow
            }
        }
        29 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value 0 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Value 1 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value 1 -Type "DWord"
            }
        }
        30 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -Type "DWord"
            }
        }
        58 {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true }
            foreach ($nic in $adapters) {
                if ($Mode -eq "Apply") {
                    Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1")
                    Write-Host "[OK] Set DNS 1.1.1.1 / 1.0.0.1 on $($nic.Name)" -ForegroundColor Green
                } else {
                    Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ResetServerAddresses
                    Write-Host "[REVERT] Reset DNS to DHCP on $($nic.Name)" -ForegroundColor Yellow
                }
            }
        }
        59 {
            if ($Mode -eq "Apply") {
                Clear-DnsClientCache
                Write-Host "[OK] Flushed local DNS cache." -ForegroundColor Green
            } else {
                Write-Host "[INFO] [#59] DNS cache repopulates automatically as you browse." -ForegroundColor Yellow
            }
        }
        60 {
            if ($Mode -eq "Apply") {
                netsh int ip reset | Out-Null
                netsh winsock reset | Out-Null
                Write-Host "[OK] Reset TCP/IP and Winsock catalog (reboot required)." -ForegroundColor Green
            } else {
                Write-Host "[INFO] [#60] Winsock/TCP reset restores clean Windows networking defaults." -ForegroundColor Yellow
            }
        }
        89 {
            $nlPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default`$windows.data.bluelightreduction.settings\windows.data.bluelightreduction.settings"
            if ($Mode -eq "Apply") {
                if (Test-Path $nlPath) {
                    Write-Host "[OK] Night Light CloudStore profile found. Opening Night Light settings..." -ForegroundColor Green
                }
                Start-Process "ms-settings:nightlight"
            } else {
                Start-Process "ms-settings:nightlight"
            }
        }
        103 {
            if ($Mode -eq "Apply") {
                Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
                Checkpoint-Computer -Description "Manual-HUD-Checkpoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
                Write-Host "[OK] System Restore Point checkpoint triggered." -ForegroundColor Green
            } else {
                Start-Process "rstrui.exe"
            }
        }
        default {
            Write-Warning "Tweak #$tweak is manual/BIOS/workflow-only or not in the automated scriptable set."
        }
    }
}

Write-Host "$Mode complete! Restart your PC to apply kernel, registry, and GPU changes." -ForegroundColor Yellow