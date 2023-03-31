function Get-LabVHDX
{
    [OutputType([AutomatedLab.Disk])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    $lab = Get-Lab

    if ($lab.DefaultVirtualizationEngine -ne 'HyperV') # We should not even be here!
    {
        return
    }

    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $disks = $lab.Disks | Where-Object Name -In $Name
    }

    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $disks = $lab.Disks
    }

    if (-not (Get-LabMachineDefinition -ErrorAction SilentlyContinue))
    {
        Import-LabDefinition -Name $lab.Name
        Import-Lab -Name $lab.Name -NoDisplay -NoValidation -DoNotRemoveExistingLabPSSessions
    }

    if ($disks)
    {
        foreach ($disk in $disks)
        {
            if ($vm = Get-LabMachineDefinition | Where-Object { $_.Disks.Name -contains $disk.Name })
            {
                $disk.Path = Join-Path -Path $lab.Target.Path -ChildPath $vm.ResourceName
            }
            else
            {
                $disk.Path = Join-Path -Path $lab.Target.Path -ChildPath Disks
            }
            $disk.Path = Join-Path -Path $disk.Path -ChildPath ($disk.Name + '.vhdx')
        }

        Write-LogFunctionExit -ReturnValue $disks.ToString()

        return $disks
    }
    else
    {
        return
    }
}
