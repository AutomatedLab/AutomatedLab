function New-LabVHDX
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName')]
        [string[]]$Name,

        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    Write-PSFMessage -Message 'Stopping the ShellHWDetection service (Shell Hardware Detection) to prevent the OS from responding to the new disks.'
    Stop-ShellHWDetectionService

    if ($Name)
    {
        $disks = Get-LabVHDX -Name $Name
    }
    else
    {
        $disks = Get-LabVHDX -All
    }

    if (-not $disks)
    {
        Write-PSFMessage -Message 'No disks found to create. Either the given name is wrong or there is no disk defined yet'
        Write-LogFunctionExit
        return
    }

    $createOnlyReferencedDisks = Get-LabConfigurationItem -Name CreateOnlyReferencedDisks
    
    $param = @{
        ReferenceObject  = $disks
        DifferenceObject = (Get-LabVM | Where-Object { -not $_.SkipDeployment }).Disks
        ExcludeDifferent = $true
        IncludeEqual     = $true
    }
    $referencedDisks = (Compare-Object @param).InputObject
    if ($createOnlyReferencedDisks -and $($disks.Count - $referencedDisks.Count) -gt 0)
    {
        Write-ScreenInfo "There are $($disks.Count - $referencedDisks.Count) disks defined that are not referenced by any machine. These disks won't be created." -Type Warning
        $disks = $referencedDisks
    }

    foreach ($disk in $disks)
    {
        Write-ScreenInfo -Message "Creating disk '$($disk.Name)'" -TaskStart -NoNewLine
        
        if (-not (Test-Path -Path $disk.Path))
        {
            $params = @{
                VhdxPath = $disk.Path
                SizeInGB = $disk.DiskSize
                SkipInitialize = $disk.SkipInitialization
                Label = $disk.Label
                UseLargeFRS = $disk.UseLargeFRS
                AllocationUnitSize = $disk.AllocationUnitSize
                PartitionStyle = $disk.PartitionStyle
            }
            if ($disk.DriveLetter)
            {
                $params.DriveLetter = $disk.DriveLetter
            }
            New-LWVHDX @params
            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
        else
        {
            Write-ScreenInfo "The disk '$($disk.Path)' does already exist, no new disk is created." -Type Warning -TaskEnd
        }
    }

    Write-PSFMessage -Message 'Starting the ShellHWDetection service (Shell Hardware Detection) again.'
    Start-ShellHWDetectionService

    Write-LogFunctionExit
}
