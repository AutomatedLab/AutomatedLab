function Get-LabVolumesOnPhysicalDisks
{
    [CmdletBinding()]

    $physicalDisks = Get-PhysicalDisk
    $disks = Get-CimInstance -Class Win32_DiskDrive

    $labVolumes = foreach ($disk in $disks)
    {
        $query = 'ASSOCIATORS OF {{Win32_DiskDrive.DeviceID="{0}"}} WHERE AssocClass=Win32_DiskDriveToDiskPartition' -f $disk.DeviceID.Replace('\', '\\')

        $partitions = Get-CimInstance -Query $query
        foreach ($partition in $partitions)
        {
            $query = 'ASSOCIATORS OF {{Win32_DiskPartition.DeviceID="{0}"}} WHERE AssocClass=Win32_LogicalDiskToPartition' -f $partition.DeviceID
            $volumes = Get-CimInstance -Query $query

            foreach ($volume in $volumes)
            {
                Get-Volume -DriveLetter $volume.DeviceId[0] |
                Add-Member -Name Serial -MemberType NoteProperty -Value $disk.SerialNumber -PassThru |
                Add-Member -Name Signature -MemberType NoteProperty -Value $disk.Signature -PassThru
            }
        }
    }

    $labVolumes |
    Select-Object -ExpandProperty DriveLetter |
    Sort-Object |
    ForEach-Object {
        $localDisk = New-Object AutomatedLab.LocalDisk($_)
        $localDisk.Serial = $_.Serial
        $localDisk.Signature = $_.Signature
        $localDisk
    }
}
