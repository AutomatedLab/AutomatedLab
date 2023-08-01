function Set-LabDefinition
{
    param
    (
        [AutomatedLab.Lab]
        $Lab,

        [AutomatedLab.Machine[]]
        $Machines,

        [AutomatedLab.Disk[]]
        $Disks
    )

    if ($Lab)
    {
        $script:lab = $Lab
    }

    if ($Machines)
    {
        if (-not $script:machines)
        {
            $script:machines = New-Object 'AutomatedLab.SerializableList[AutomatedLab.Machine]'
        }

        $script:machines.Clear()
        $Machines | ForEach-Object { $script:Machines.Add($_) }
    }

    if ($Disks)
    {
        $script:Disks.Clear()
        $Disks | ForEach-Object { $script:Disks.Add($_) }
    }
}
