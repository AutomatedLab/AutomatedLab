function Get-LabSourcesLocationInternal
{
    param
    (
        [switch]$Local
    )

    $lab = $global:AL_CurrentLab

    $defaultEngine = 'HyperV'
    $defaultEngine = if ($lab)
    {
        $lab.DefaultVirtualizationEngine
    }

    if ($lab.AzureSettings -and $lab.AzureSettings.IsAzureStack)
    {
        $Local = $true
    }

    if ($defaultEngine -eq 'kvm' -or ($IsLinux -and $Local.IsPresent))
    {
        if (-not (Get-PSFConfigValue -FullName AutomatedLab.LabSourcesLocation))
        {
            Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Description 'Location of lab sources folder' -Value $home/automatedlabsources -PassThru | Register-PSFConfig
        }

        Get-PSFConfigValue -FullName AutomatedLab.LabSourcesLocation
    }
    elseif (($defaultEngine -eq 'HyperV' -or $Local) -and (Get-PSFConfigValue AutomatedLab.LabSourcesLocation))
    {
        Get-PSFConfigValue -FullName AutomatedLab.LabSourcesLocation
    }
    elseif ($defaultEngine -eq 'HyperV' -or $Local)
    {
        $hardDrives = (Get-CimInstance -NameSpace Root\CIMv2 -Class Win32_LogicalDisk | Where-Object DriveType -In 2, 3).DeviceID | Sort-Object -Descending

        $folders = foreach ($drive in $hardDrives)
        {
            if (Test-Path -Path "$drive\LabSources")
            {
                "$drive\LabSources"
            }
        }

        if ($folders.Count -gt 1)
        {
            Write-PSFMessage -Level Warning "The LabSources folder is available more than once ('$($folders -join "', '")'). The LabSources folder must exist only on one drive and in the root of the drive."
        }

        $folders
    }
    elseif ($defaultEngine -eq 'Azure')
    {
        try
        {
            (Get-LabAzureLabSourcesStorage -ErrorAction Stop).Path
        }
        catch
        {
            Get-LabSourcesLocationInternal -Local
        }
    }
    else
    {
        Get-LabSourcesLocationInternal -Local
    }
}
