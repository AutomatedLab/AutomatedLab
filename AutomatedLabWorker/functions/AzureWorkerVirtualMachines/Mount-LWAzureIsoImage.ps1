function Mount-LWAzureIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification = "Not relevant, used in Invoke-LabCommand")]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [string]
        $IsoPath,

        [switch]$PassThru
    )

    Test-LabHostConnected -Throw -Quiet

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount
    $azureIsoPath = $IsoPath -replace '/', '\' -replace 'https:'
    # ISO file should already exist on Azure storage share, as it was initially retrieved from there as well.

    # Path is local (usually Azure Stack which has no storage file shares)
    if (-not (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $azureIsoPath))
    {
        Write-ScreenInfo -type Info -Message "Copying $azureIsoPath to $($ComputerName -join ',')"
        Copy-LabFileItem -Path $azureIsoPath -ComputerName $ComputerName -DestinationFolderPath C:\ALMounts
        $result = Invoke-LabCommand -ActivityName "Mounting $(Split-Path $azureIsoPath -Leaf) on $($ComputerName -join ',')" -ComputerName $ComputerName -ScriptBlock {
            $drive = Mount-DiskImage -ImagePath C:\ALMounts\$(Split-Path -Leaf -Path $azureIsoPath) -StorageType ISO -PassThru | Get-Volume
            $drive | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($drive.CimInstanceProperties.Item('DriveLetter').Value + ":") -Force
            $drive | Add-Member -MemberType NoteProperty -Name InternalComputerName -Value $env:COMPUTERNAME -Force
            $drive | Select-Object -Property *
        } -Variable (Get-Variable azureIsoPath) -PassThru:$PassThru.IsPresent

        if ($PassThru.IsPresent) { return $result } else { return }
    }

    Invoke-LabCommand -ActivityName "Mounting $(Split-Path $azureIsoPath -Leaf) on $($ComputerName -join ',')" -ComputerName $ComputerName -ScriptBlock {

        if (-not (Test-Path -Path $azureIsoPath))
        {
            throw "'$azureIsoPath' is not accessible."
        }

        $drive = Mount-DiskImage -ImagePath $azureIsoPath -StorageType ISO -PassThru | Get-Volume
        $drive | Add-Member -MemberType NoteProperty -Name DriveLetter -Value ($drive.CimInstanceProperties.Item('DriveLetter').Value + ":") -Force
        $drive | Add-Member -MemberType NoteProperty -Name InternalComputerName -Value $env:COMPUTERNAME -Force
        $drive | Select-Object -Property *

    } -ArgumentList $azureIsoPath -Variable (Get-Variable -Name azureIsoPath) -PassThru:$PassThru
}
