New-ClusterNode
Enable-ClusterStorageSpacesDirect

New-VirtualDisk <resiliencysettingname> <Parity> <storagefriendlyname> <capacity,performance> <storagetiersizes> <x,y>
Get-VirtualDisk <name> |make-pretty

Add-ClusterNode
Remove-ClusterNode
Get-ClusterNode

Get-PhysicalDisk -canpool $true |sort model

Get-StoragePool * |Get-PhysicalDisk 

Get-StorageJob

$cluster = get-storagesubsystem
$volume = get-storagesubsystem |get-volume



Test-Cluster -Node S2D-VMH-01, S2D-VMH-02, S2D-VMH-03, S2D-VMH-04 -Include "Storage Spaces Direct"


Test-Cluster �Node S2D-VMH-01, S2D-VMH-02, S2D-VMH-03, S2D-VMH-04 �Include "Storage Spaces Direct", "Inventory", "Network", "System Configuration"
New-Cluster -Name S2DCLUSTER1 -node S2D-VMH-01, S2D-VMH-02, S2D-VMH-03, S2D-VMH-04 -NoStorage -StaticAddress 172.16.0.60/16

Enable-ClusterStorageSpacesDirect -CimSession S2DCLUSTER1
Get-NetAdapterAdvancedProperty -Name * -RegistryKeyword "*jumbopacket" | Set-NetAdapterAdvancedProperty -RegistryValue 9014

$Volume = Get-Volume -FileSystemLabel "S2D-VMH-01"
$Partition = $Volume | Get-Partition
$Disk = $Partition | Get-Disk
$VirtualDisk = $Disk | Get-VirtualDisk

1..4 | Foreach { New-Volume -FriendlyName "S2D-VMH-0$_" -FileSystem CSVFS_ReFS -StoragePoolFriendlyName S2D -Size 1TB -ResiliencySettingName Parity }

Enable-VMMigration �Computername S2D-VMH-01, S2D-VMH-02, S2D-VMH-03, S2D-VMH-04
Set-VMHost -MaximumVirtualMachineMigrations 4 `
           �MaximumStorageMigrations 4 `
           �VirtualMachineMigrationPerformanceOption SMB `
           -ComputerName S2D-VMH-01, S2D-VMH-02, S2D-VMH-03, S2D-VMH-04


# kerberos authentication for live migration
Enter-PSSession -ComputerName dc03.macleans.school.nz
$HyvHost = "S2D-VMH-01"
$Domain = "macleans.school.nz"
 
Get-ADComputer $HyvHost | Set-ADObject -Add @{"msDS-AllowedToDelegateTo"="Microsoft Virtual System Migration Service/$HyvHost.$Domain", "cifs/$HyvHost.$Domain","Microsoft Virtual System Migration Service/$HyvHost", "cifs/$HyvHost"}
 
$HyvHost = "S2D-VMH-02"
Get-ADComputer $HyvHost | Set-ADObject -Add @{"msDS-AllowedToDelegateTo"="Microsoft Virtual System Migration Service/$HyvHost.$Domain", "cifs/$HyvHost.$Domain","Microsoft Virtual System Migration Service/$HyvHost", "cifs/$HyvHost"}
$HyvHost = "S2D-VMH-03"
Get-ADComputer $HyvHost | Set-ADObject -Add @{"msDS-AllowedToDelegateTo"="Microsoft Virtual System Migration Service/$HyvHost.$Domain", "cifs/$HyvHost.$Domain","Microsoft Virtual System Migration Service/$HyvHost", "cifs/$HyvHost"}
$HyvHost = "S2D-VMH-04"
Get-ADComputer $HyvHost | Set-ADObject -Add @{"msDS-AllowedToDelegateTo"="Microsoft Virtual System Migration Service/$HyvHost.$Domain", "cifs/$HyvHost.$Domain","Microsoft Virtual System Migration Service/$HyvHost", "cifs/$HyvHost"}
exit # breaks from ps-session


Set-VMHost -Computername  S2D-VMH-01, S2D-VMH-02, S2D-VMH-03, S2D-VMH-04 -VirtualMachineMigrationAuthenticationType Kerberos



# networking Jumbo Frames


interface ethernet 1/1/1 shutdown
interface ethernet 1/1/1 mtu 9216
interface ethernet 1/1/1 no shutdown

interface ethernet 1/1/2 shutdown
interface ethernet 1/1/2 mtu 9216
interface ethernet 1/1/2 no shutdown


interface ethernet 1/2/1 shutdown
interface ethernet 1/2/1 mtu 9216
interface ethernet 1/2/1 no shutdown

interface ethernet 1/2/2 shutdown
interface ethernet 1/2/2 mtu 9216
interface ethernet 1/2/2 no shutdown

