function New-LabVM
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [switch]$CreateCheckPoints,

        [int]$ProgressIndicator = 20
    )

    Write-LogFunctionEntry

    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM -ComputerName $Name -IncludeLinux -ErrorAction Stop | Where-Object { -not $_.SkipDeployment }

    if (-not $machines)
    {
        $message = 'No machine found to create. Either the given name is wrong or there is no machine defined yet'
        Write-LogFunctionExitWithError -Message $message
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for all machines to finish installing' -TaskStart
    foreach ($machine in $machines.Where({$_.HostType -ne 'Azure'}))
    {
        $fdvDenyWriteAccess = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE -Name FDVDenyWriteAccess -ErrorAction SilentlyContinue).FDVDenyWriteAccess
        if ($fdvDenyWriteAccess) {
            Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE -Name FDVDenyWriteAccess -Value 0
        }

        Write-ScreenInfo -Message "Creating $($machine.HostType) machine '$machine'" -TaskStart -NoNewLine

        if ($machine.HostType -eq 'HyperV')
        {
            $result = New-LWHypervVM -Machine $machine

            $doNotAddToCluster = Get-LabConfigurationItem -Name DoNotAddVmsToCluster -Default $false
            if (-not $doNotAddToCluster -and (Get-Command -Name Get-Cluster -Module FailoverClusters -CommandType Cmdlet -ErrorAction SilentlyContinue) -and (Get-Cluster -ErrorAction SilentlyContinue -WarningAction SilentlyContinue))
            {
                Write-ScreenInfo -Message "Adding $($machine.Name) ($($machine.ResourceName)) to cluster $((Get-Cluster).Name)"
                if (-not (Get-ClusterGroup -Name $machine.ResourceName -ErrorAction SilentlyContinue))
                {
                    $null = Add-ClusterVirtualMachineRole -VMName $machine.ResourceName -Name $machine.ResourceName
                }
            }

            if ('RootDC' -in $machine.Roles.Name)
            {
                Start-LabVM -ComputerName $machine.Name -NoNewline
            }

            if ($result)
            {
                Write-ScreenInfo -Message 'Done' -TaskEnd
            }
            else
            {
                Write-ScreenInfo -Message "Could not create $($machine.HostType) machine '$machine'" -TaskEnd -Type Error
            }
        }
        elseif ($machine.HostType -eq 'VMWare')
        {
            $vmImageName = (New-Object AutomatedLab.OperatingSystem($machine.OperatingSystem)).VMWareImageName
            if (-not $vmImageName)
            {
                Write-Error "The VMWare image for operating system '$($machine.OperatingSystem)' is not defined in AutomatedLab. Cannot install the machine."
                continue
            }

            New-LWVMWareVM -Name $machine.Name -ReferenceVM $vmImageName -AdminUserName $machine.InstallationUser.UserName -AdminPassword $machine.InstallationUser.Password `
            -DomainName $machine.DomainName -DomainJoinCredential $machine.GetCredential($lab)

            Start-LabVM -ComputerName $machine
        }
        
        if ($fdvDenyWriteAccess) {
            Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Policies\Microsoft\FVE -Name FDVDenyWriteAccess -Value $fdvDenyWriteAccess
        }
    }

    if ($lab.DefaultVirtualizationEngine -eq 'Azure')
    {
        $deployment = New-LabAzureResourceGroupDeployment -Lab $lab -PassThru -Wait -ErrorAction SilentlyContinue -ErrorVariable rgDeploymentFail
        if (-not $deployment)
        {
            $labFolder = Split-Path -Path $lab.LabFilePath -Parent
            Write-ScreenInfo "The deployment failed. To get more information about the  following error, please run the following command:"
            Write-ScreenInfo "'New-AzResourceGroupDeployment -ResourceGroupName $($lab.AzureSettings.DefaultResourceGroup.ResourceGroupName) -TemplateFile $labFolder\armtemplate.json'"
            Write-LogFunctionExitWithError -Message "Deployment of resource group '$lab' failed with '$($rgDeploymentFail.Exception.Message)'" -ErrorAction Stop
        }
    }

    Write-ScreenInfo -Message 'Done' -TaskEnd

    $azureVms = Get-LabVM -ComputerName $machines -IncludeLinux | Where-Object { $_.HostType -eq 'Azure' -and -not $_.SkipDeployment }
    $winAzVm, $linuxAzVm = $azureVms.Where({$_.OperatingSystemType -eq 'Windows'})

    if ($azureVMs)
    {
        Write-ScreenInfo -Message 'Initializing machines' -TaskStart

        Write-PSFMessage -Message 'Calling Enable-PSRemoting on machines'
        Enable-LWAzureWinRm -Machine $winAzVm -Wait

        Write-PSFMessage -Message 'Executing initialization script on machines'
        Initialize-LWAzureVM -Machine $azureVMs

        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    $vmwareVMs = $machines | Where-Object HostType -eq VMWare

    if ($vmwareVMs)
    {
        throw New-Object System.NotImplementedException
    }

    Write-LogFunctionExit
}
