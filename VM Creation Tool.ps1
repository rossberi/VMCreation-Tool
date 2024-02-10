#VM Name angeben + pr�fen, ob vorhanden
$VMName = Read-Host "VM Name"
if (get-vm -name $VMName -ErrorAction SilentlyContinue) {
    Write-Error "Diese VM existiert schon!"
    return #bricht Skript ab
}

#VHDX erstellen
if (!(Test-Path "C:\VM\$VMName\Virtual Hard Disks\$VMName.vhdx" -PathType leaf)) {
    [int]$VMDisk = Read-Host "VM Fetsplattenkapazitaet (in GB)"
    New-VHD -Path "C:\VM\$VMName\Virtual Hard Disks\$VMName.vhdx" -Fixed -SizeBytes ($VMDisk * 1024 * 1024 * 1024) -PhysicalSectorSizeBytes 4096
}

#Eingabe der VM Daten
[int]$VMMem = Read-Host "VM Ram (in GB)"
$maxCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
[int]$VMCore = Read-Host "VM Kerne (Max: $maxCores Kerne)"
$VMGen = Read-Host "VM Generation: (1 oder 2 (UEFI = Standard)"
if ($VMGen -eq "") {
    $VMGen = 2
}
$VMSwitch = Read-Host "Name des virtuellen Switch (leer = automatische Auswahl)"

#VMSwitch
if ($VMSwitch -eq "") {
    $VMSwitch = Get-VMSwitch | Select-Object Name | Format-Table -HideTableHeaders | Out-String
    $VMSwitch = $VMSwitch.Trim()
    if ($VMSwitch -eq "") {
        Write-Error "Es existiert kein VM Switch, bitte erstell einen, bevor du eine VM erstellst."
        return
    }
}

#VM erstellen
New-VM -Name $VMName -MemoryStartupBytes ($VMMem * 1024 * 1024 * 1024) -BootDevice VHD -VHDPath "C:\VM\$VMName\Virtual Hard Disks\$VMName.vhdx" -Path "C:\VM\" -Generation $VMGen -Switch "$VMSwitch"
Set-VM -Name $VMName -AutomaticStartAction "StartIfRunning" -AutomaticStopAction "Shutdown" -ProcessorCount $VMCore

#ISO Images
Write-Host " "
Write-Host "---"
Write-Host " "

$ISOs = Get-ChildItem -Path ./isos -Name
[int]$zaehler = 0
Write-Host "0: Keine ISO einlegen"
foreach ($ISO in $ISOs) {
    [int]$zaehler = [int]$zaehler + 1
    Write-Host $zaehler": $ISO" 
}

Write-Host " "
Write-Host "---"
Write-Host " "
[int]$intImage = Read-Host "Nutze ein Image mit der Zahl zwischen 0 und $zaehler"
[int]$intImage = [int]$intImage - 1

if ($intImage -gt $zaehler) {
    Write-Host "Bitte geb einen zulaessigen Wert an"
    return #abbruch Skript, bei unzulässigem Wert
}

#Change Bootorder
if (!($intImage -eq -1)) {
    if($ISOs -is [string]){
        ADD-VMDvdDrive -VMName $VMName -Path ".\isos\$ISOs"
    } else {
        $IsoPath = $ISOs[$intImage]
        ADD-VMDvdDrive -VMName $VMName -Path ".\isos\$IsoPath"
    }

    $VMBoot = Get-VMFirmware $VMName
    $hddrive = $VMBoot.BootOrder[0]
    $pxe = $VMBoot.BootOrder[1]
    $dvddrive = $VMBoot.BootOrder[2]
    Set-VMFirmware -VMName $VMName -BootOrder $dvddrive, $hddrive, $pxe
}
