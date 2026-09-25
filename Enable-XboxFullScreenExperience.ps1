#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks the current Windows device form factor and, if it is not
    already "Gaming handheld", offers to switch it so the Xbox Full
    Screen Experience toggle appears in Settings > Gaming (e.g. on
    the ROG Ally).

    No arguments needed — just run it.
#>

$RegPath    = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\OEM'
$ValueName  = 'DeviceForm'
$BackupFile = "$env:ProgramData\DeviceForm_backup.txt"

$DeviceForms = @{
    0="Unknown"; 1="Phone"; 2="Tablet"; 3="Desktop"; 4="Notebook";
    5="Convertible"; 6="Detachable"; 7="All-in-One"; 8="Stick PC"; 9="Puck";
    10="Surface Hub"; 11="Head-mounted display"; 12="Industry handheld";
    13="Industry tablet"; 14="Banking"; 15="Building automation";
    16="Digital signage"; 17="Gaming"; 18="Home automation";
    19="Industrial automation"; 20="Kiosk"; 21="Maker board"; 22="Medical";
    23="Networking"; 24="Point of Service"; 25="Printing"; 26="Thin client";
    27="Toy"; 28="Vending"; 29="Industry other"; 46="Gaming handheld"
}
$GamingHandheldValue = 46

if (-not (Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

try {
    $current = (Get-ItemProperty -Path $RegPath -Name $ValueName -ErrorAction Stop).$ValueName
} catch {
    $current = $null
}

if ($null -eq $current) {
    Write-Host "Current device form: not set."
} else {
    $name = $DeviceForms[$current]
    if (-not $name) { $name = "Unrecognized value" }
    Write-Host ("Current device form: {0} (0x{0:X2}) -> {1}" -f $current, $name)
}

# If a backup from a previous change exists, offer to restore or delete it
if (Test-Path $BackupFile) {
    $backupValue = [int](Get-Content $BackupFile)
    $backupName  = $DeviceForms[$backupValue]
    if (-not $backupName) { $backupName = "Unrecognized value" }

    Write-Host ""
    Write-Host ("A backup exists from a previous change: {0} (0x{0:X2}) -> {1}" -f $backupValue, $backupName)
    $choice = Read-Host "Restore this value, delete the backup, or skip? [R]estore / [D]elete / [S]kip"

    switch -Regex ($choice) {
        '^(r|restore)$' {
            Set-ItemProperty -Path $RegPath -Name $ValueName -Value $backupValue -Type DWord
            Remove-Item $BackupFile -Force
            Write-Host ("Device form restored to: {0} (0x{0:X2}) -> {1}" -f $backupValue, $backupName)
            Write-Host "Reboot required for this to take effect."
            exit 0
        }
        '^(d|delete)$' {
            Remove-Item $BackupFile -Force
            Write-Host "Backup file deleted. No other changes made."
            exit 0
        }
        default {
            Write-Host "Skipping backup file."
        }
    }
}

if ($current -eq $GamingHandheldValue) {
    Write-Host "Already set to Gaming handheld. Nothing to do."
    exit 0
}

$answer = Read-Host "Switch to 'Gaming handheld' to enable the Xbox Full Screen Experience? (Y/N)"

if ($answer -notmatch '^(y|yes)$') {
    Write-Host "No changes made."
    exit 0
}

if (-not (Test-Path $BackupFile) -and $null -ne $current) {
    $current | Out-File -FilePath $BackupFile -Encoding ascii
    Write-Host "Backed up previous value ($current) to $BackupFile"
}

Set-ItemProperty -Path $RegPath -Name $ValueName -Value $GamingHandheldValue -Type DWord
Write-Host ("Device form updated to: {0} (0x{0:X2}) -> Gaming handheld" -f $GamingHandheldValue)
Write-Host "Reboot required for the Full screen experience toggle to appear in Settings > Gaming."
