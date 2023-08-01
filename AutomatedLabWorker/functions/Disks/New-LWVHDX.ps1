function New-LWVHDX
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding()]
    Param (
        #Path to reference VHD
        [Parameter(Mandatory = $true)]
        [string]$VhdxPath,

        #Size of the reference VHD
        [Parameter(Mandatory = $true)]
        [int]$SizeInGB,

        [string]$Label,

        [switch]$UseLargeFRS,

        [char]$DriveLetter,

        [long]$AllocationUnitSize,

        [string]$PartitionStyle,

        [switch]$SkipInitialize
    )

    Write-LogFunctionEntry

    $PSBoundParameters.Add('ProgressIndicator', 1) #enables progress indicator

    $VmDisk = New-VHD -Path $VhdxPath -SizeBytes ($SizeInGB * 1GB) -ErrorAction Stop
    Write-ProgressIndicator
    Write-PSFMessage "Created VHDX file '$($vmDisk.Path)'"

    if ($SkipInitialize)
    {
        Write-PSFMessage -Message "Skipping the initialization of '$($vmDisk.Path)'"
        Write-LogFunctionExit
        return
    }

    $mountedVhd = $VmDisk | Mount-VHD -PassThru
    Write-ProgressIndicator

    if ($DriveLetter)
    {
        $Label += "_AL_$DriveLetter"
    }

    $formatParams = @{
        FileSystem = 'NTFS'
        NewFileSystemLabel = 'Data'
        Force = $true
        Confirm = $false
        UseLargeFRS = $UseLargeFRS
        AllocationUnitSize = $AllocationUnitSize
    }
    if ($Label)
    {
        $formatParams.NewFileSystemLabel = $Label
    }

    $mountedVhd | Initialize-Disk -PartitionStyle $PartitionStyle
    $mountedVhd | New-Partition -UseMaximumSize -AssignDriveLetter |
    Format-Volume @formatParams |
    Out-Null

    Write-ProgressIndicator

    $VmDisk | Dismount-VHD

    Write-LogFunctionExit
}
