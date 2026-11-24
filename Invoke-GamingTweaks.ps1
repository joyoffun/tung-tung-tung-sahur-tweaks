#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Native Windows Forms desktop GUI for the scriptable tweaks from the 105-Tweak Optimization HUD.
.DESCRIPTION
    Opens a desktop window (no web browser required) to apply or roll back selected
    power, registry, visual, game-bar, network, and restore-point tweaks.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

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

function Invoke-TweakById {
    param (
        [Parameter(Mandatory)] [int] $Id,
        [Parameter(Mandatory)] [ValidateSet("Apply", "Rollback")] [string] $Mode,
        [Parameter(Mandatory)] [System.Windows.Forms.TextBox] $LogBox
    )

    switch ($Id) {
        2 {
            if ($Mode -eq "Apply") {
                $ultOut = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
                if ($ultOut -match "([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})") {
                    powercfg /setactive $Matches[1] | Out-Null
                    $LogBox.AppendText("[OK] #2 Activated Ultimate Performance Plan ($($Matches[1])).`r`n")
                } else {
                    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null | Out-Null
                    $LogBox.AppendText("[OK] #2 Activated High Performance fallback plan.`r`n")
                }
            } else {
                powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null | Out-Null
                $LogBox.AppendText("[REVERT] #2 Restored Balanced power plan.`r`n")
            }
        }
        4 {
            $val = if ($Mode -eq "Apply") { 1 } else { 3 }
            Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #4 Diagnostic telemetry (AllowTelemetry) -> $val`r`n")
        }
        5 {
            $val = if ($Mode -eq "Apply") { 1 } else { 0 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #5 Storage Sense policy -> $val`r`n")
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
            $LogBox.AppendText("[$Mode] #6 Visual effects & animations updated.`r`n")
        }
        7 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #7 Delivery Optimization mode -> $val`r`n")
        }
        8 {
            $val = if ($Mode -eq "Apply") { 2 } else { 1 }
            Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #8 HAGS (HwSchMode) -> $val`r`n")
        }
        9 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #9 Fast Startup (HiberbootEnabled) -> $val`r`n")
        }
        10 {
            if ($Mode -eq "Apply") {
                powercfg -h off | Out-Null
                $LogBox.AppendText("[OK] #10 Hibernation disabled (hiberfil.sys removed).`r`n")
            } else {
                powercfg -h on | Out-Null
                $LogBox.AppendText("[REVERT] #10 Hibernation re-enabled.`r`n")
            }
        }
        11 {
            $godPath = "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"
            if ($Mode -eq "Apply") {
                if (-not (Test-Path $godPath)) {
                    New-Item -Path $godPath -ItemType Directory -Force | Out-Null
                }
                $LogBox.AppendText("[OK] #11 Created God Mode folder on Desktop.`r`n")
            } elseif (Test-Path $godPath) {
                Remove-Item -Path $godPath -Force -Recurse
                $LogBox.AppendText("[REVERT] #11 Removed God Mode folder from Desktop.`r`n")
            }
        }
        12 {
            $clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
            if ($Mode -eq "Apply") {
                New-Item -Path $clsidPath -Force | Out-Null
                Set-ItemProperty -Path $clsidPath -Name "(Default)" -Value "" -Force
                $LogBox.AppendText("[OK] #12 Classic Windows 11 right-click menu enabled.`r`n")
            } else {
                Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
                $LogBox.AppendText("[REVERT] #12 Restored default Windows 11 context menu.`r`n")
            }
        }
        13 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value $val -Type "DWord"
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #13 Lock screen tips/ads -> $val`r`n")
        }
        14 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #14 Transparency effects -> $val`r`n")
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
            $LogBox.AppendText("[$Mode] #15 Sticky/Filter Keys prompts updated.`r`n")
        }
        16 {
            $val = if ($Mode -eq "Apply") { 1 } else { 0 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #16 Clipboard history (Win+V) -> $val`r`n")
        }
        17 {
            $endHour = if ($Mode -eq "Apply") { 23 } else { 17 }
            Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursStart" -Value 8 -Type "DWord"
            Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursEnd" -Value $endHour -Type "DWord"
            $LogBox.AppendText("[$Mode] #17 Update active hours -> 8 AM to $endHour:00.`r`n")
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
            $LogBox.AppendText("[$Mode] #18 Xbox Game Bar capture updated.`r`n")
        }
        19 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #19 Core Isolation (Memory Integrity) -> $val`r`n")
        }
        22 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #22 Remote Assistance -> $val`r`n")
        }
        24 {
            if ($Mode -eq "Apply") {
                Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue | Out-Null
                $LogBox.AppendText("[OK] #24 SSD TRIM ran on C:.`r`n")
            } else {
                $LogBox.AppendText("[INFO] #24 SSD TRIM is non-destructive (no rollback needed).`r`n")
            }
        }
        26 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value $val -Type "DWord"
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value $val -Type "DWord"
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #26 Suggested content / ads -> $val`r`n")
        }
        27 {
            if ($Mode -eq "Apply") {
                if (Get-Command winget -ErrorAction SilentlyContinue) {
                    $LogBox.AppendText("[INFO] #27 Running winget upgrade --all in background...`r`n")
                    Start-Process -FilePath "winget" -ArgumentList "upgrade --all --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait
                    $LogBox.AppendText("[OK] #27 winget upgrade finished.`r`n")
                } else {
                    $LogBox.AppendText("[WARN] #27 winget not found.`r`n")
                }
            } else {
                $LogBox.AppendText("[INFO] #27 winget updates have no automatic rollback.`r`n")
            }
        }
        29 {
            $val = if ($Mode -eq "Apply") { 0 } else { 1 }
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent" -Value $val -Type "DWord"
            Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowFrequent" -Value $val -Type "DWord"
            $LogBox.AppendText("[$Mode] #29 Explorer recent/frequent -> $val`r`n")
        }
        30 {
            if ($Mode -eq "Apply") {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type "DWord"
            } else {
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -Type "DWord"
                Set-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -Type "DWord"
            }
            $LogBox.AppendText("[$Mode] #30 File extensions & hidden items updated.`r`n")
        }
        58 {
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface -eq $true }
            foreach ($nic in $adapters) {
                if ($Mode -eq "Apply") {
                    Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1")
                    $LogBox.AppendText("[OK] #58 Set DNS 1.1.1.1 / 1.0.0.1 on $($nic.Name).`r`n")
                } else {
                    Set-DnsClientServerAddress -InterfaceIndex $nic.ifIndex -ResetServerAddresses
                    $LogBox.AppendText("[REVERT] #58 Reset DNS to DHCP on $($nic.Name).`r`n")
                }
            }
        }
        59 {
            if ($Mode -eq "Apply") {
                Clear-DnsClientCache
                $LogBox.AppendText("[OK] #59 Flushed local DNS cache.`r`n")
            } else {
                $LogBox.AppendText("[INFO] #59 DNS cache repopulates automatically.`r`n")
            }
        }
        60 {
            if ($Mode -eq "Apply") {
                netsh int ip reset | Out-Null
                netsh winsock reset | Out-Null
                $LogBox.AppendText("[OK] #60 Reset TCP/IP & Winsock (reboot required).`r`n")
            } else {
                $LogBox.AppendText("[INFO] #60 Winsock/TCP reset uses clean Windows defaults.`r`n")
            }
        }
        89 {
            Start-Process "ms-settings:nightlight"
            $LogBox.AppendText("[$Mode] #89 Opened Night Light settings.`r`n")
        }
        103 {
            if ($Mode -eq "Apply") {
                Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
                try {
                    Checkpoint-Computer -Description "PC-Tweak-GUI-Checkpoint" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                    $LogBox.AppendText("[OK] #103 Created System Restore Point.`r`n")
                } catch {
                    $LogBox.AppendText("[WARN] #103 Restore Point skipped (Windows allows 1 automatic point per 24h).`r`n")
                }
            } else {
                Start-Process "rstrui.exe"
                $LogBox.AppendText("[REVERT] #103 Opened System Restore (rstrui.exe).`r`n")
            }
        }
    }
}

# Build Native Windows Forms Window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Optimization Controller (Desktop GUI)"
$form.Size = New-Object System.Drawing.Size(640, 560)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

$checklist = New-Object System.Windows.Forms.CheckedListBox
$checklist.Location = New-Object System.Drawing.Point(16, 16)
$checklist.Size = New-Object System.Drawing.Size(592, 270)
$checklist.CheckOnClick = $true

$tweakEntries = @(
    @{ Id = 2;   Text = "#2 Unlock & Activate Ultimate Performance Power Plan" },
    @{ Id = 4;   Text = "#4 Reduce Diagnostic Telemetry (Required Only)" },
    @{ Id = 5;   Text = "#5 Enable Storage Sense" },
    @{ Id = 6;   Text = "#6 Tune Visual Effects (Keep Smooth Fonts, Disable Animations)" },
    @{ Id = 7;   Text = "#7 Disable Update Delivery Optimization Sharing" },
    @{ Id = 8;   Text = "#8 Enable Hardware-Accelerated GPU Scheduling (HAGS)" },
    @{ Id = 9;   Text = "#9 Disable Fast Startup" },
    @{ Id = 10;  Text = "#10 [Caution] Disable Hibernation (hiberfil.sys)" },
    @{ Id = 11;  Text = "#11 Create God Mode Control Folder on Desktop" },
    @{ Id = 12;  Text = "#12 Restore Classic Right-Click Context Menu (Win 11)" },
    @{ Id = 13;  Text = "#13 Disable Lock Screen Tips & Ads" },
    @{ Id = 14;  Text = "#14 Turn Off Transparency Effects" },
    @{ Id = 15;  Text = "#15 Disable Sticky Keys & Filter Keys Prompts" },
    @{ Id = 16;  Text = "#16 Enable Clipboard History (Win + V)" },
    @{ Id = 17;  Text = "#17 Set Windows Update Active Hours (8 AM - 11 PM)" },
    @{ Id = 18;  Text = "#18 Disable Xbox Game Bar & Background Capture" },
    @{ Id = 19;  Text = "#19 [Caution] Disable Core Isolation (Memory Integrity)" },
    @{ Id = 22;  Text = "#22 Disable Remote Assistance" },
    @{ Id = 24;  Text = "#24 Run SSD TRIM Optimization on C:" },
    @{ Id = 26;  Text = "#26 Disable Suggested Content in Start & Settings" },
    @{ Id = 27;  Text = "#27 Batch Update Apps via winget" },
    @{ Id = 29;  Text = "#29 Turn Off File Explorer Recent/Frequent Clutter" },
    @{ Id = 30;  Text = "#30 Show File Extensions & Hidden Items" },
    @{ Id = 58;  Text = "#58 Set Cloudflare DNS (1.1.1.1 / 1.0.0.1)" },
    @{ Id = 59;  Text = "#59 Flush Local DNS Cache" },
    @{ Id = 60;  Text = "#60 [Caution] Reset Winsock & TCP/IP Stack" },
    @{ Id = 89;  Text = "#89 Open Night Light Settings" },
    @{ Id = 103; Text = "#103 Create System Restore Point" }
)

foreach ($entry in $tweakEntries) {
    $defaultChecked = ($entry.Id -notin @(10, 19, 60, 27))
    [void]$checklist.Items.Add($entry.Text, $defaultChecked)
}

$btnApply = New-Object System.Windows.Forms.Button
$btnApply.Text = "Apply Selected"
$btnApply.Location = New-Object System.Drawing.Point(16, 298)
$btnApply.Size = New-Object System.Drawing.Size(140, 34)

$btnRollback = New-Object System.Windows.Forms.Button
$btnRollback.Text = "Rollback Selected"
$btnRollback.Location = New-Object System.Drawing.Point(166, 298)
$btnRollback.Size = New-Object System.Drawing.Size(145, 34)

$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(321, 298)
$btnSelectAll.Size = New-Object System.Drawing.Size(95, 34)

$btnClearAll = New-Object System.Windows.Forms.Button
$btnClearAll.Text = "Clear All"
$btnClearAll.Location = New-Object System.Drawing.Point(424, 298)
$btnClearAll.Size = New-Object System.Drawing.Size(95, 34)

$logBox = New-Object System.Windows.Forms.TextBox
$logBox.Location = New-Object System.Drawing.Point(16, 344)
$logBox.Size = New-Object System.Drawing.Size(592, 160)
$logBox.Multiline = $true
$logBox.ScrollBars = "Vertical"
$logBox.ReadOnly = $true
$logBox.Text = "Ready. Check tweaks above and click 'Apply Selected' or 'Rollback Selected'.`r`n"

function Get-SelectedTweakIds {
    $ids = @()
    for ($i = 0; $i -lt $checklist.Items.Count; $i++) {
        if ($checklist.GetItemChecked($i)) {
            $ids += $tweakEntries[$i].Id
        }
    }
    return $ids
}

$btnApply.Add_Click({
    $ids = Get-SelectedTweakIds
    $logBox.AppendText("--- Applying $($ids.Count) selected tweak(s) ---`r`n")
    foreach ($id in $ids) {
        Invoke-TweakById -Id $id -Mode "Apply" -LogBox $logBox
    }
    $logBox.AppendText("--- Done. Restart your PC for full effect. ---`r`n")
})

$btnRollback.Add_Click({
    $ids = Get-SelectedTweakIds
    $logBox.AppendText("--- Rolling back $($ids.Count) selected tweak(s) ---`r`n")
    foreach ($id in $ids) {
        Invoke-TweakById -Id $id -Mode "Rollback" -LogBox $logBox
    }
    $logBox.AppendText("--- Rollback complete. Restart your PC if needed. ---`r`n")
})

$btnSelectAll.Add_Click({
    for ($i = 0; $i -lt $checklist.Items.Count; $i++) {
        $checklist.SetItemChecked($i, $true)
    }
})

$btnClearAll.Add_Click({
    for ($i = 0; $i -lt $checklist.Items.Count; $i++) {
        $checklist.SetItemChecked($i, $false)
    }
})

$form.Controls.AddRange(@($checklist, $btnApply, $btnRollback, $btnSelectAll, $btnClearAll, $logBox))
$form.Add_Shown({ $form.TopMost = $false; $form.Activate() })
[void]$form.ShowDialog()