$VMName = Read-Host "VM Name:"
$VMExists = get-vm -name $VMName -ErrorAction SilentlyContinue
If ($VMExists){
	Write "Diese VM existiert schon"
}
Else {

    [int]$VMDisk = Read-Host "VM Fetsplattengröße: "
    [int]$VMMem = Read-Host "VM Ram (in GB):"
    [int]$VMCore = Read-Host "VM Kerne:"
    $VMGen = Read-Host "VM Generation: (1 oder 2 (UEFI): "
    $VMSwitch = Read-Host "Name des virtuellen Switch:"

	if (Test-Path "C:\VM\$VMName\Virtual Hard Disks\$VMName.vhdx" -PathType leaf)
    {

    }else {
        New-VHD -Path "C:\VM\$VMName\Virtual Hard Disks\$VMName.vhdx" -Fixed -SizeBytes ($VMDisk*1024*1024*1024) -PhysicalSectorSizeBytes 4096
    }

        New-VM -Name $VMName -MemoryStartupBytes ($VMMem*1024*1024*1024) -BootDevice VHD -VHDPath "C:\VM\$VMName\Virtual Hard Disks\$VMName.vhdx" -Path "C:\VM\" -Generation $VMGen -Switch $VMSwitch
        Set-VM -Name $VMName -AutomaticStartAction "StartIfRunning" -AutomaticStopAction "Shutdown" -ProcessorCount $VMCore

}