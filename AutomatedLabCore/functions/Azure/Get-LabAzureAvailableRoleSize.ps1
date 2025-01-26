function Get-LabAzureAvailableRoleSize
{
    [CmdletBinding(DefaultParameterSetName = 'DisplayName')]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'DisplayName')]
        [Alias('Location')]
        [string]
        $DisplayName,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]
        $LocationName
    )

    Test-LabHostConnected -Throw -Quiet

    if (-not (Get-AzContext -ErrorAction SilentlyContinue))
    {
        $param = @{
            UseDeviceAuthentication = $true
            ErrorAction             = 'SilentlyContinue'
            WarningAction           = 'Continue'
        }

        if ($script:lab.AzureSettings.Environment)
        {
            $param.Environment = $script:Lab.AzureSettings.Environment
        }

        $null = Connect-AzAccount @param
    }

    $azLocation = Get-AzLocation | Where-Object { $_.DisplayName -eq $DisplayName -or $_.Location -eq $LocationName }
    if (-not $azLocation)
    {
        Write-ScreenInfo -Type Error -Message "No location found matching DisplayName '$DisplayName' or Name '$LocationName'"
        return
    }

    $availableRoleSizes = Get-AzComputeResourceSku -Location $azLocation.Location | Where-Object {
        $_.ResourceType -eq 'virtualMachines' -and ($_.Restrictions | Where-Object Type -eq Location).ReasonCode -ne 'NotAvailableForSubscription' -and ($_.Capabilities | Where-Object Name -eq CpuArchitectureType).Value -notlike '*arm*'
    }

    foreach ($vms in (Get-AzComputeResourceSku -Location $azLocation.Location | Where-Object -Property Name -in $availableRoleSizes.Name))
    {
        $rsInfo = $availableRoleSizes | Where-Object Name -eq $vms.Name

        [AutomatedLab.Azure.AzureRmVmSize]@{
            NumberOfCores        = $rsInfo.Capabilities.Where({ $_.Name -eq 'vCPUs' }).Value
            MemoryInMB           = [int]($rsInfo.Capabilities.Where({ $_.Name -eq 'MemoryGB' }).Value) * 1024
            Name                 = $vms.Name
            MaxDataDiskCount     = $rsInfo.Capabilities.Where({ $_.Name -eq 'MaxDataDiskCount' }).Value
            ResourceDiskSizeInMB = $rsInfo.Capabilities.Where({ $_.Name -eq 'MaxResourceVolumeMB' }).Value
            OSDiskSizeInMB       = $rsInfo.Capabilities.Where({ $_.Name -eq 'OSVhdSizeMB' }).Value
            Gen1Supported        = $rsInfo.Capabilities.Where({ $_.Name -eq 'HyperVGenerations' }).Value -like '*v1*'
            Gen2Supported        = $rsInfo.Capabilities.Where({ $_.Name -eq 'HyperVGenerations' }).Value -like '*v2*'
        }
    }
}
