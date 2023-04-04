function Start-LabVM
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(ParameterSetName = 'ByName', Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByRole')]
        [AutomatedLab.Roles]$RoleName,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,

        [switch]$Wait,

        [switch]$DoNotUseCredSsp,

        [switch]$NoNewline,

        [int]$DelayBetweenComputers = 0,

        [int]$TimeoutInMinutes = (Get-LabConfigurationItem -Name Timeout_StartLabMachine_Online),

        [int]$StartNextMachines,

        [int]$StartNextDomainControllers,

        [string]$Domain,

        [switch]$RootDomainMachines,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [int]$PreDelaySeconds = 0,

        [int]$PostDelaySeconds = 0
    )

    begin
    {
        Write-LogFunctionEntry

        if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

        $lab = Get-Lab

        if (-not $lab.Machines)
        {
            $message = 'No machine definitions imported, please use Import-Lab first'
            Write-Error -Message $message
            Write-LogFunctionExitWithError -Message $message
            return
        }

        $vms = [System.Collections.Generic.List[AutomatedLab.Machine]]::new()
        $availableVMs = $lab.Machines | Where-Object SkipDeployment -eq $false
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName' -and -not $StartNextMachines -and -not $StartNextDomainControllers)
        {
            $null = $lab.Machines | Where-Object Name -in $ComputerName | Foreach-Object { $vms.Add($_) }
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByRole' -and -not $StartNextMachines -and -not $StartNextDomainControllers)
        {
            #get all machines that have a role assigned and the machine's role name is part of the parameter RoleName
            $vms = $lab.Machines | Where-Object { $_.Roles.Name } |
            Where-Object { ($_.Roles | Where-Object { $RoleName.HasFlag([AutomatedLab.Roles]$_.Name) }) -and (-not $_.SkipDeployment) }

            if (-not $vms)
            {
                Write-Error "There is no machine in the lab with the role '$RoleName'"
                return
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByRole' -and $StartNextMachines -and -not $StartNextDomainControllers)
        {
            $vms = $lab.Machines | Where-Object { $_.Roles.Name -and ((Get-LabVMStatus -ComputerName $_.Name) -ne 'Started')} |
            Where-Object { $_.Roles | Where-Object { $RoleName.HasFlag([AutomatedLab.Roles]$_.Name) } }

            if (-not $vms)
            {
                Write-Error "There is no machine in the lab with the role '$RoleName'"
                return
            }
            $vms = $vms | Select-Object -First $StartNextMachines
        }
        elseif (-not ($PSCmdlet.ParameterSetName -eq 'ByRole') -and -not $RootDomainMachines -and -not $StartNextMachines -and $StartNextDomainControllers)
        {
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'FirstChildDC' }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'DC' }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'CaRoot' -and (-not $_.DomainName) }
            $vms = $vms | Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -ne 'Started' } | Select-Object -First $StartNextDomainControllers
        }
        elseif (-not ($PSCmdlet.ParameterSetName -eq 'ByRole') -and -not $RootDomainMachines -and $StartNextMachines -and -not $StartNextDomainControllers)
        {
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'CaRoot' -and $_.DomainName -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'CaSubordinate' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -like 'SqlServer*' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'WebServer' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'Orchestrator' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'VisualStudio2013' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'VisualStudio2015' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'Office2013' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { -not $_.Roles.Name -and $_ -notin $vms }
            $vms = $vms | Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -ne 'Started' } | Select-Object -First $StartNextMachines

            if ($Domain)
            {
                $vms = $vms | Where-Object { (Get-LabVM -ComputerName $_) -eq $Domain }
            }
        }
        elseif (-not ($PSCmdlet.ParameterSetName -eq 'ByRole') -and -not $RootDomainMachines -and $StartNextMachines -and -not $StartNextDomainControllers)
        {
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -like 'SqlServer*' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'WebServer' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'Orchestrator' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'VisualStudio2013' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'VisualStudio2015' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'Office2013' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { -not $_.Roles.Name -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'CaRoot' -and $_ -notin $vms }
            $vms += Get-LabVM -IncludeLinux | Where-Object { $_.Roles.Name -eq 'CaSubordinate' -and $_ -notin $vms }
            $vms = $vms | Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -ne 'Started' } | Select-Object -First $StartNextMachines

            if ($Domain)
            {
                $vms = $vms | Where-Object { (Get-LabVM -IncludeLinux -ComputerName $_) -eq $Domain }
            }
        }
        elseif (-not ($PSCmdlet.ParameterSetName -eq 'ByRole') -and $RootDomainMachines -and -not $StartNextDomainControllers)
        {
            $vms = Get-LabVM -IncludeLinux | Where-Object { $_.DomainName -in (Get-LabVM -Role RootDC).DomainName } | Where-Object { $_.Name -notin (Get-LabVM -Role RootDC).Name -and $_.Roles.Name -notlike '*DC' }
            $vms = $vms | Select-Object -First $StartNextMachines
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $vms = $availableVMs | Where-Object { -not $_.SkipDeployment }
        }

        $vms = $vms | Where-Object SkipDeployment -eq $false

        #if there are no VMs to start, just write a warning
        if (-not $vms)
        {
            return
        }

        $vmsCopy = $vms | Where-Object {-not ($_.OperatingSystemType -eq 'Linux' -and $_.OperatingSystem.OperatingSystemName -match ('Suse|CentOS Linux 8'))}

        #filtering out all machines that are already running
        $vmStates = Get-LabVMStatus -ComputerName $vms -AsHashTable
        foreach ($vmState in $vmStates.GetEnumerator())
        {
            if ($vmState.Value -eq 'Started')
            {
                $vms = $vms | Where-Object Name -ne $vmState.Name
                Write-Debug "Machine '$($vmState.Name)' is already running, removing it from the list of machines to start"
            }
        }

        Write-PSFMessage "Starting VMs '$($vms.Name -join ', ')'"

        $hypervVMs = $vms | Where-Object HostType -eq 'HyperV'
        if ($hypervVMs)
        {
            Start-LWHypervVM -ComputerName $hypervVMs -DelayBetweenComputers $DelayBetweenComputers -ProgressIndicator $ProgressIndicator -PreDelaySeconds $PreDelaySeconds -PostDelaySeconds $PostDelaySeconds -NoNewLine:$NoNewline
            
            foreach ($vm in $hypervVMs)
            {
                $machineMetadata = Get-LWHypervVMDescription -ComputerName $vm.ResourceName
                if (($machineMetadata.InitState -band [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected) -ne [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected)
                {
                    Repair-LWHypervNetworkConfig -ComputerName $vm
                    $machineMetadata.InitState = [AutomatedLab.LabVMInitState]::NetworkAdapterBindingCorrected
                    Set-LWHypervVMDescription -Hashtable $machineMetadata -ComputerName $vm.ResourceName
                }
            }
        }

        $azureVms = $vms | Where-Object HostType -eq 'Azure'
        if ($azureVms)
        {
            Start-LWAzureVM -ComputerName $azureVms -DelayBetweenComputers $DelayBetweenComputers -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewline
        }

        $vmwareVms = $vms | Where-Object HostType -eq 'VmWare'
        if ($vmwareVms)
        {
            Start-LWVMWareVM -ComputerName $vmwareVms -DelayBetweenComputers $DelayBetweenComputers
        }

        if ($Wait -and $vmsCopy)
        {
            Wait-LabVM -ComputerName ($vmsCopy) -Timeout $TimeoutInMinutes -DoNotUseCredSsp:$DoNotUseCredSsp -ProgressIndicator $ProgressIndicator -NoNewLine
        }

        Write-ProgressIndicatorEnd

        Write-LogFunctionExit
    }
}
