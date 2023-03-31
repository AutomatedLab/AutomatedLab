function Add-LabDiskDefinition
{
    [CmdletBinding()]
    [OutputType([AutomatedLab.Disk])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateScript( {
                $doesAlreadyExist = Test-Path -Path $_
                if ($doesAlreadyExist)
                {
                    Write-ScreenInfo 'The disk does already exist' -Type Warning
                    return $false
                }
                else
                {
                    return $true
                }
            }
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [int]$DiskSizeInGb = 60,

        [string]$Label,

        [char]$DriveLetter,

        [switch]$UseLargeFRS,

        [long]$AllocationUnitSize = 4KB,

        [ValidateSet('MBR','GPT')]
        [string]
        $PartitionStyle = 'GPT',

        [switch]$SkipInitialize,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ($null -eq $script:disks)
    {
        $errorMessage = "Create a new lab first using 'New-LabDefinition' before adding disks"
        Write-Error $errorMessage
        Write-LogFunctionExitWithError -Message $errorMessage
        return
    }

    if ($Name)
    {
        if ($script:disks | Where-Object Name -eq $Name)
        {
            $errorMessage = "A disk with the name '$Name' does already exist"
            Write-Error $errorMessage
            Write-LogFunctionExitWithError -Message $errorMessage
            return
        }
    }

    $disk = New-Object -TypeName AutomatedLab.Disk
    $disk.Name = $Name
    $disk.DiskSize = $DiskSizeInGb
    $disk.SkipInitialization = [bool]$SkipInitialize
    $disk.AllocationUnitSize = $AllocationUnitSize
    $disk.UseLargeFRS = $UseLargeFRS
    $disk.DriveLetter = $DriveLetter
    $disk.PartitionStyle = $PartitionStyle
    $disk.Label = if ($Label)
    {
        $Label
    }
    else
    {
        'ALData'
    }

    $script:disks.Add($disk)

    Write-PSFMessage "Added disk '$Name' with path '$Path'. Lab now has $($Script:disks.Count) disk(s) defined"

    if ($PassThru)
    {
        $disk
    }

    Write-LogFunctionExit
}
