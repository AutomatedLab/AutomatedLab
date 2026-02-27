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
    foreach ($machine in $machines.Where({$_.HostType -notin 'Azure', 'Proxmox'}))
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

    if ($proxmoxVMs = $machines.Where({$_.HostType -eq 'Proxmox' -and -not $_.SkipDeployment }))
    {
        if (-not (Test-LabProxmoxConnection))
        {
            Write-ScreenInfo -Message 'There is no connection to Proxmox, cannot create VMs.' -Type Error
            Write-Error 'There is no connection to Proxmox, cannot create VMs.' -ErrorAction Stop
        }

        $rootDCs = $proxmoxVMs.Where({$_.Roles.Name -contains 'RootDC'})
        $firstChildDCs = $proxmoxVMs.Where({$_.Roles.Name -contains 'FirstChildDC'})
        $otherVMs = $proxmoxVMs.Where({ $_.Roles.Name -notin 'RootDC', 'FirstChildDC' })

        #-------------------------------------------------------------------

        if ($rootDCs)
        {
            foreach ($rootDC in $rootDCs)
            {
                New-LWProxmoxVM -Machine $rootDC | Out-Null
            }
            Wait-LabVM -ComputerName $rootDCs #Stop and start is required to sync the time with the Proxmox host

            Repair-LWHypervNetworkConfig -ComputerName $rootDCs -ErrorAction SilentlyContinue
            #TODO: Is this still required?
            #Stop-LabVM -ComputerName $rootDCs -Wait
            #Start-LabVM -ComputerName $rootDCs -Wait

            $sysprepState = Get-LWProxmoxVMSysprepState -ComputerName $rootDCs
            if ($sysprepState | Where-Object SysprepState -ne 'IMAGE_STATE_COMPLETE')
            {
                Write-Error "The following Proxmox VMs did not complete sysprep: $($sysprepState | Where-Object SysprepState -ne 'IMAGE_STATE_COMPLETE' | Select-Object -ExpandProperty ComputerName -Unique -Join ', ')"
            }
            Install-LabRootDcs
        }

        #-------------------------------------------------------------------

        if ($firstChildDCs)
        {
            foreach ($firstChildDC in $firstChildDCs)
            {
                New-LWProxmoxVM -Machine $firstChildDC | Out-Null
            }
            Wait-LabVM -ComputerName $firstChildDCs

            Repair-LWHypervNetworkConfig -ComputerName $firstChildDCs -ErrorAction SilentlyContinue

            $sysprepState = Get-LWProxmoxVMSysprepState -ComputerName $firstChildDCs
            if ($sysprepState | Where-Object SysprepState -ne 'IMAGE_STATE_COMPLETE')
            {
                Write-Error "The following Proxmox VMs did not complete sysprep: $($sysprepState | Where-Object SysprepState -ne 'IMAGE_STATE_COMPLETE' | Select-Object -ExpandProperty ComputerName -Unique -Join ', ')"
            }
            Install-LabFirstChildDcs
        }

        #-------------------------------------------------------------------

        if ($otherVMs)
        {
            foreach ($otherVM in $otherVMs)
            {
                New-LWProxmoxVM -Machine $otherVM | Out-Null
            }

            Wait-LabVM -ComputerName $otherVMs

            Repair-LWHypervNetworkConfig -ComputerName $otherVMs -ErrorAction SilentlyContinue

            $sysprepState = Get-LWProxmoxVMSysprepState -ComputerName $otherVMs
            # As the machine's name is not yet set we likely run into the default retry behavior resulting in 3 entries returned. Hence, we get only the last one per machine.
            $sysprepState = $sysprepState | Group-Object -Property ComputerName | ForEach-Object { $_.Group[-1] }

            if ($sysprepState | Where-Object SysprepState -ne 'IMAGE_STATE_COMPLETE')
            {
                Write-Error "The following Proxmox VMs did not complete sysprep: $(($sysprepState | Where-Object SysprepState -ne 'IMAGE_STATE_COMPLETE' | Select-Object -ExpandProperty ComputerName -Unique) -Join ', ')"
            }
        }

        Write-Host 'done.'
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
