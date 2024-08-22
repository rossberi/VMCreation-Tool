#Configuration Templates
$templates = @(
    @{
        templateName = "Windows 4C/8GB/100GB"
        templateMemory = 8   # GB
        templateCores = 4
        templateDisk = 100 # GB
        templateGeneration = 2
        templateTPM = "y"
        templateSecureBoot = "y"

    },
    @{
        templateName = "Windows 8C/32GB/100GB"
        templateMemory = 32   # GB
        templateCores = 8
        templateDisk = 100 # GB
        templateGeneration = 2
        templateTPM = "y"
        templateSecureBoot = "y"
    },
    @{
        templateName = "Windows 16C/64GB/100GB"
        templateMemory = 64   # GB
        templateCores = 16
        templateDisk = 100 # GB
        templateGeneration = 2
        templateTPM = "y"
        templateSecureBoot = "y"
    },
    @{
        templateName = "Linux 4C/8GB/50GB"
        templateMemory = 8   # GB
        templateCores = 4
        templateDisk = 50 # GB
        templateGeneration = 2
        templateTPM = "n"
        templateSecureBoot = "n"
    }
)

#Vars
$VMPath = "C:\VM"


#StoredValues
$VMCompleted = $false
$VMName = ""
$VMDisk = 0
$VMMem = 0
$VMCore = 0
$VMGen = 2
$VMSwitch = ""
$VMTPM = "y"
$VMSecureBoot = "y"
$VMImage = 0


function Get-UserInput {
    param (
        [string]$Prompt,
        [string]$DefaultValue = ""
    )
    
    $input = Read-Host "$Prompt [Standard: $DefaultValue]"
    if ($input -eq "" -and $DefaultValue -ne "") {
        return $DefaultValue
    }
    return $input
}

function Get-AvailableMemory {
    # Gesamten physischen Speicher auf dem Host abfragen
    $totalMemoryGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)

    # Speicher, der von anderen VMs verwendet wird
    $usedMemoryGB = (Get-VM | Where-Object {$_.State -eq 'Running'} | Measure-Object -Property MemoryAssigned -Sum).Sum / 1GB

    # Verfügbarer Speicher
    $freeMemoryGB = [math]::Round($totalMemoryGB - $usedMemoryGB, 2)
    
    return $freeMemoryGB
}

function Get-FreeDiskSpace {
    param (
        [string]$vmDiskPath
    )

    try {
        # Extrahiere den Laufwerksbuchstaben aus dem Pfad
        $driveLetter = (Split-Path $vmDiskPath -Qualifier).TrimEnd('\').TrimEnd(':')

        # Prüfe, ob das Laufwerk existiert
        $driveInfo = Get-PSDrive -Name $driveLetter -ErrorAction Stop

        # Berechne den verfügbaren Speicherplatz
        $freeSpace = [math]::Round($driveInfo.Free / 1GB, 2)
        return $freeSpace
    }
    catch {
        Write-Host "Fehler: Das Laufwerk '$driveLetter' wurde nicht gefunden oder ist nicht verfügbar." -ForegroundColor Red
        return $null
    }
}

function Get-VMSwitchName {

    # Abfrage der verfügbaren virtuellen Switches
    $VMSwitches = Get-VMSwitch | Select-Object -ExpandProperty Name

    # Überprüfen, ob der angegebene SwitchName in der Liste vorhanden ist
    if ($VMSwitches) {
        $SwitchName = $VMSwitches[0]
        return $SwitchName
    } else {
        return ""
    }
}

function Set-VMName {
    do {
        $VMName = Get-UserInput -Prompt "VM Name"
        if ($VMName -eq "") {
            Write-Host "Der VM Name darf nicht leer sein!" -ForegroundColor Red
        } elseif (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
            Write-Host "Eine VM mit diesem Namen existiert bereits!" -ForegroundColor Red
            $VMName = ""
        }
    } while ($VMName -eq "")
    return $VMName
}

function Set-VMTemplate {
    # Template Auswahl
    Write-Host "Verfügbare Templates:"
    for ($i = 0; $i -lt $templates.Count; $i++) {
        Write-Host "$($i + 1): $($templates[$i].templateName)"
    }

    [int]$templateChoice = Get-UserInput -Prompt "Wähle ein Template (Zahl)" -DefaultValue 1
    $template = $templates[$templateChoice - 1]
    return $template
}

cls

$VMName = Set-VMName

$template = Set-VMTemplate

$VMMem = $template.templateMemory
$VMCore = $template.templateCores
$VMDisk = $template.templateDisk
$VMGen = $template.templateGeneration
$VMTPM = $template.templateTPM
$VMSecureBoot = $template.templateSecureBoot
$VMSwitch = Get-VMSwitchName

cls

do {
    cls
    Write-Host "---------ERROR--------"
    Write-Host $LastError -ForegroundColor Red
    Write-Host ""
    Write-Host "----------------------"
    Write-Host "VM Konfigurationsmenü"
    Write-Host "----------------------"
    Write-Host "1.  VM Name: $VMName"
    Write-Host "2.  Festplattenkapazität: $VMDisk GB"
    Write-Host "3.  Arbeitsspeicher: $VMMem GB"
    Write-Host "4.  Anzahl der Kerne: $VMCore"
    Write-Host "5.  VM Generation: $VMGen"
    Write-Host "6.  Virtueller Switch: $VMSwitch"
    Write-Host "7.  TPM aktivieren: $VMTPM"
    Write-Host "8.  Secure Boot aktivieren: $VMSecureBoot"
    Write-Host "9.  ISO auswählen: $VMImage"
    Write-Host "10. Alle Daten bestätigen und VM erstellen"
    Write-Host "11. Template ändern"
    Write-Host "0.  Beenden"

    $LastError = ""

    $choice = Read-Host "Wähle eine Option, um sie zu bearbeiten, oder 10 zum Bestätigen"
    switch ($choice) {
        1 {
            $VMName = Set-VMName
        }
        2 {
            $freeSpace = Get-FreeDiskSpace -vmDiskPath $VMPath
            [int]$VMDisktmp = Get-UserInput -Prompt "Festplattenkapazität (in GB)" -DefaultValue $template.templateDisk
            if ($VMDisktmp -le 0) {
                $LastError = "Die Festplattenkapazität muss größer als 0 sein!"
            } elseif ($VMDisktmp -gt $freeSpace) {
                $LastError = "Nicht genügend Speicherplatz verfügbar. Freier Speicher: $freeSpace GB"
            }else {
                $VMDisk = $VMDisktmp
            }
            
        }
        3 {
            [int]$VMMemtmp = Get-UserInput -Prompt "Arbeitsspeicher (in GB)" -DefaultValue $template.templateMemory
            $availableMemoryGB = Get-AvailableMemory
            
            if ($VMMemtmp -le 0) {
                $LastError = "Die Arbeitsspeichermenge muss größer als 0 sein!"
            } elseif ($VMMemtmp -gt $availableMemoryGB) {
                $LastError = "Nicht genügend Arbeitsspeicher verfügbar. Verfügbarer Speicher: $availableMemoryGB GB"
            }else {
                $VMMem = $VMMemtmp
            }
        }
        4 {
            # Maximale Anzahl der logischen Prozessoren auf dem Host ermitteln
            $maxCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

            # Anzahl der Kerne abfragen und sicherstellen, dass sie nicht größer als maxCores ist
            $VMCoretmp = [int](Get-UserInput -Prompt "Anzahl der Kerne (Max: $maxCores)" -DefaultValue $template.templateCores)
            
            if ($VMCoretmp -le 0) {
                $LastError = "Die Anzahl der Kerne muss größer als 0 sein!" 
            } elseif ($VMCoretmp -gt $maxCores) {
                $LastError = "Die Anzahl der Kerne darf die maximale Anzahl von $maxCores Kernen auf dem Host nicht überschreiten!"
            }else {
                $VMCore = $VMCoretmp
            }
            
        }
        5 {
            $VMGen = Get-UserInput -Prompt "VM Generation (1 oder 2)" -DefaultValue $template.templateGeneration
            if ($VMGen -eq "") { $VMGen = 2 }
        }
        6 {
            # Alle verfügbaren virtuellen Switches abrufen
            $VMSwitches = Get-VMSwitch | Select-Object -ExpandProperty Name

            # Eine Option für "Keinen Switch verwenden" hinzufügen
            $VMSwitchOptions = @("Keinen Switch verwenden") + $VMSwitches

            [int]$zaehler = 1
            Write-Host "Verfügbare virtuelle Switches:"
            foreach ($Switch in $VMSwitchOptions) {
                Write-Host "$zaehler : $Switch"
                $zaehler++
            }

            # Benutzer zur Auswahl eines Switches auffordern
            $switchChoice = [int](Get-UserInput -Prompt "Wähle einen Switch" -DefaultValue "1")

            # Überprüfen, ob die Wahl innerhalb des gültigen Bereichs liegt
            if ($switchChoice -lt 1 -or $switchChoice -gt $VMSwitchOptions.Count) {
                $LastError = "Ungültige Auswahl. Standardmäßig wird kein Switch verwendet."
                $VMSwitch = "" # Kein Switch
            } else {
                # Wenn der Benutzer "Keinen Switch verwenden" wählt
                if ($switchChoice -eq 1) {
                    $VMSwitch = "" # Kein Switch verwenden
                } else {
                    # Anderen Switch aus der Liste wählen
                    $VMSwitch = $VMSwitchOptions[$switchChoice - 1]
                }
            }
        }
        7 {
            if ($VMGen -eq 2) {
                $VMTPM = Get-UserInput -Prompt "TPM aktivieren? ((y)es / (n)o)" -DefaultValue $template.templateTPM
            } else {
                Write-Host "TPM kann nur für Generation 2 VMs aktiviert werden."
            }
        }
        8 {
            if ($VMGen -eq 2) {
                $VMSecureBoot = Get-UserInput -Prompt "SecureBoot aktivieren? ((y)es / (n)o)" -DefaultValue $template.templateSecureBoot
            } else {
                Write-Host "Secure Boot kann nur für Generation 2 VMs aktiviert werden."
            }
        }
        9 {

            # Alle verfügbaren virtuellen Switches abrufen
            $ISOs = Get-ChildItem -Path "./isos" -Name
            # Eine Option für "Keinen Switch" hinzufügen
            $ISOOptions = @("Keine ISO verwenden") + $ISOs
            [int]$zaehler = 0
            Write-Host "Verfügbare ISO-Images:"
            foreach ($ISO in $ISOOptions) {
                [int]$zaehler = [int]$zaehler + 1
                Write-Host "$zaehler : $ISO"
            }
            $VMImagetmp = Get-UserInput -Prompt "Wähle ein Image (Zahl)" -DefaultValue "1"
            if ($VMImagetmp -gt $zaehler) {
                Write-Host "Ungültige Auswahl, keine ISO wird verwendet."
            }else{
                $VMImage = $VMImagetmp
            }
        }
        10 {
            $VMCompleted = $true
        }
        11 {
            $template = Set-VMTemplate
        }
        0 {
            Write-Host "Skript beendet."
            return
        }
        default {
            Write-Host "Ungültige Auswahl. Bitte versuche es erneut."
        }
    }
} while (-not $VMCompleted)

if ($VMCompleted){
    # Alle Daten sind gesammelt, jetzt wird die VM erstellt
    $VMDiskPath = "$VMPath\$VMName\Virtual Hard Disks"

    # VHDX erstellen
    if (!(Test-Path "$VMDiskPath\$VMName.vhdx" -PathType Leaf)) {
        New-VHD -Path "$VMDiskPath\$VMName.vhdx" -Fixed -SizeBytes ($VMDisk * 1024 * 1024 * 1024) -PhysicalSectorSizeBytes 4096
    }

    # VM erstellen

    New-VM -Name $VMName -MemoryStartupBytes ($VMMem * 1024 * 1024 * 1024) -BootDevice VHD -VHDPath "$VMDiskPath\$VMName.vhdx" -Path "$VMPath\" -Generation $VMGen

    if ($VMSwitch) {
        # Switch wurde angegeben
        # Netzwerkkarte hinzufügen
        Get-VMNetworkAdapter -VMName $VMName| Connect-VMNetworkAdapter -SwitchName $VMSwitch
    }

    Set-VM -Name $VMName -AutomaticStartAction "StartIfRunning" -AutomaticStopAction "Shutdown" -ProcessorCount $VMCore

    # Secure Boot aktivieren, falls gewünscht
    if ($VMSecureBoot -eq "y" -and $VMGen -eq 2) {
        Set-VMFirmware -VMName $VMName -EnableSecureBoot On
        Write-Host "Secure Boot wurde aktiviert."

        # TPM aktivieren
        if ($VMTPM -eq "y" -and $VMGen -eq 2) {
            Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector
            # TPM mit der erstellten Schlüsselschutzvorrichtung aktivieren
            Enable-VMTPM -VMName $VMName
            Write-Host "TPM wurde aktiviert."
        }
    }else {
        Set-VMFirmware -VMName $VMName -EnableSecureBoot Off
        Write-Host "Secure Boot wurde deaktiviert."
    }

    # DVD Laufwerk hinzufügen und Bootreihenfolge ändern
    if (!($VMImage -eq 1)) {
        $IsoPath = $ISOOptions[$VMImage -1]
        ADD-VMDvdDrive -VMName $VMName -Path ".\isos\$IsoPath"

        $VMBoot = Get-VMFirmware $VMName
        $hddrive = $VMBoot.BootOrder[0]
        $pxe = $VMBoot.BootOrder[1]
        $dvddrive = $VMBoot.BootOrder[2]
        Set-VMFirmware -VMName $VMName -BootOrder $dvddrive, $hddrive, $pxe
    }

    Write-Host "VM $VMName wurde erfolgreich erstellt."
}