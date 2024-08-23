# HyperV VM Creation Script

Dieses PowerShell-Skript unterstützt beim Erstellen von virtuellen Maschinen (VMs) auf einem Hyper-V Host. Es vereinfacht und automatisiert den Prozess der Erstellung neuer VMs, inklusive der Auswahl von ISOs und weiteren notwendigen Einstellungen.

## Features

- Automatisierte Erstellung von VMs auf einem Hyper-V Host.
- Auswahl der verwendeten ISOs aus einem definierten Ordner.
- Einfache Anpassung der VM-Konfiguration (RAM, CPU, etc.).

## Voraussetzungen

- Ein Windows-Host mit Hyper-V aktiviert.
- PowerShell v5.1 oder höher.
- Administratorrechte auf dem Hyper-V Host.
- Ein Verzeichnis für die benötigten ISOs.

## Installation

1. **Erstelle die notwendigen Verzeichnisse:**
   - Erstelle den Ordner `C:\Downloads`, falls dieser nicht bereits existiert:
     ```powershell
     New-Item -Path "C:\Downloads" -ItemType Directory
     ```
   - Erstelle im selben Verzeichnis einen Ordner namens `isos`, in dem alle benötigten ISO-Dateien abgelegt werden:
     ```powershell
     New-Item -Path "C:\Downloads\isos" -ItemType Directory
     ```

2. **Lade das Skript herunter:**
   - Führe den folgenden PowerShell-Befehl aus, um das Skript direkt von GitHub herunterzuladen und in das Verzeichnis `C:\Downloads` zu speichern:
     ```powershell
     $fileUrl = "https://raw.githubusercontent.com/rossberi/VMCreation-Tool/main/VM%20Creation%20Tool.ps1"
     $outputPath = "C:\Downloads\VM Creation Tool.ps1"
     Invoke-WebRequest -Uri $fileUrl -OutFile $outputPath
     ```

## Nutzung

### Vorbereitung

Um das Skript auszuführen, muss die PowerShell Execution Policy auf `Bypass` gesetzt werden. Führe dazu folgenden Befehl in PowerShell aus:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

**Hinweis:** Setze die Execution Policy nach der Nutzung wieder auf `RemoteSigned` zurück, um Sicherheitsrisiken zu minimieren:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force
```

### Ausführen des Skripts

#### Direkt auf dem Hyper-V Host

Wenn du direkt auf dem Hyper-V Host arbeitest, kannst du das Skript direkt aus dem Verzeichnis ausführen:
```powershell
.\C:\Downloads\VM Creation Tool.ps1
```

#### Remote-Verbindung zum Hyper-V Host

Wenn du das Skript von einem anderen Computer ausführen möchtest, stelle zuerst eine Remote PowerShell-Sitzung zum Hyper-V Host her. Stelle sicher, dass der Computer, von dem aus du dich verbindest, in derselben Domäne wie der Hyper-V Host ist:
```powershell
Enter-PSSession -ComputerName <Servername>
```

Führe das Skript dann innerhalb der Sitzung aus:
```powershell
.\C:\Downloads\VM Creation Tool.ps1
```

## Support

Wenn du Probleme mit dem Skript hast oder Verbesserungsvorschläge hast, öffne bitte ein Issue in diesem Repository.
