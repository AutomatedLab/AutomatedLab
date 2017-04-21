#region New-LabVM
function New-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
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
    
    if ($Name)
    {
        $machines = Get-LabVM -ComputerName $Name
    }
    else
    {
        $machines = Get-LabVM
    }
    
    if (-not $machines)
    {
        $message = 'No machine found to create. Either the given name is wrong or there is no machine defined yet'
        Write-LogFunctionExitWithError -Message $message
        return
    }
    
    $jobs = @()

    if($lab.DefaultVirtualizationEngine -eq 'Azure')
    {		
        Write-ScreenInfo -Message 'Creating Azure load balancer for the newly created machines' -TaskStart
        New-LWAzureLoadBalancer -ConnectedMachines ($machines.Where({ $_.HostType -eq 'Azure' })) -Wait
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    foreach ($machine in $machines)
    {
        Write-ScreenInfo -Message "Creating $($machine.HostType) machine '$machine'" -TaskStart -NoNewLine
        
        if ($machine.HostType -eq 'HyperV')
        {		
            $result = New-LWHypervVM -Machine $machine
            
            if ('RootDC' -in $machine.Roles.Name)
            {
                Start-LabVM -ComputerName $machine.Name
            }
            
            if ($result)
            {
                Write-ProgressIndicatorEnd
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
        elseif ($machine.HostType -eq 'Azure')
        {
            $jobs += New-LWAzureVM -Machine $machine
            
            Write-ScreenInfo -Message 'Done' -TaskEnd
        }
    }
    
    #test if the machine creation jobs succeeded
    Write-ScreenInfo -Message 'Waiting for all machines to finish installing' -TaskStart
    $jobs | Wait-Job | Out-Null
    $failedJobs = $jobs | Where-Object State -eq 'Failed'
    $completedJobs = $jobs | Where-Object State -eq 'Completed'
    Write-ScreenInfo -Message 'Done' -TaskEnd

    if ($failedJobs)
    {
        $machinesFailedToCreate = ($failedJobs.Name | ForEach-Object { ($_ -split '\(|\)')[3] }) -join ', '
        throw "Failed to create the following Azure machines: $machinesFailedToCreate'. For further information take a look at the background job's result (Get-Job, Receive-Job)"
    }
            
    if ($completedJobs)
    {
        $azureVMs = $completedJobs.Name | ForEach-Object { ($_ -split '\(|\)')[3] }
        $azureVMs = Get-LabMachine -ComputerName $azureVMs
    }

    if ($azureVMs)
    {
        Write-ScreenInfo -Message 'Initializing machines' -TaskStart

        Write-Verbose -Message 'Calling Enable-PSRemoting on machines'
        Enable-LWAzureWinRm -Machine $azureVMs -Wait

        Write-Verbose -Message 'Setting lab DNS servers for newly created machines'
        Set-LWAzureDnsServer -VirtualNetwork $lab.VirtualNetworks

        Write-Verbose -Message 'Executing initialization script on machines'
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
#endregion New-LabVM

#region Start-LabVM
function Start-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(ParameterSetName = 'ByName', Position = 0)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ParameterSetName = 'ByRole')]
        [AutomatedLab.Roles]$RoleName,
        
        [Parameter(ParameterSetName = 'All')]
        [switch]$All,
        
        [switch]$Wait,
        
        [switch]$DoNotUseCredSsp,

        [switch]$NoNewline,

        [int]$DelayBetweenComputers = 0,
        
        [int]$TimeoutInMinutes = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_StartLabMachine_Online,

        [int]$StartNextMachines,
        
        [int]$StartNextDomainControllers,
        
        [string]$Domain,

        [switch]$RootDomainMachines,

        [int]$ProgressIndicator,

        [int]$PreDelaySeconds = 0,

        [int]$PostDelaySeconds = 0
    )
    
    begin
    {
        Write-LogFunctionEntry
        
        $lab = Get-Lab
        
        $vms = @()
        $availableVMs = $lab.Machines
    }
    
    process
    {
        
        if (-not $lab.Machines)
        {
            $message = 'No machine definitions imported, please use Import-Lab first'
            Write-Error -Message $message
            Write-LogFunctionExitWithError -Message $message
            return
        }
        
        if ($PSCmdlet.ParameterSetName -eq 'ByName' -and -not $StartNextMachines -and -not $StartNextDomainControllers)
        {
            $vms = Get-LabMachine -ComputerName $ComputerName
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByRole' -and -not $StartNextMachines -and -not $StartNextDomainControllers)
        {
            #get all machines that have a role assigned and the machine's role name is part of the parameter RoleName
            $vms = $lab.Machines | Where-Object { $_.Roles.Name } |
            Where-Object { $_.Roles | Where-Object { $RoleName.HasFlag([AutomatedLab.Roles]$_.Name) } }
            
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
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'FirstChildDC' }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'DC' }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'CaRoot' -and (-not $_.DomainName) }

            $vms = $vms | Select-Object *, @{name='OSversion';expression={$_.OperatingSystem.Version}} | Sort-Object -Property OSversion
            $vms = $vms | Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -ne 'Started' } | Select-Object -First $StartNextDomainControllers
        }
        elseif (-not ($PSCmdlet.ParameterSetName -eq 'ByRole') -and -not $RootDomainMachines -and $StartNextMachines -and -not $StartNextDomainControllers)
        {
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'CaRoot' -and $_.DomainName -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'CaSubordinate' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -like 'SqlServer*' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'WebServer' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'Orchestrator' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'Exchange2013' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'Exchange2016' -and $_ -notin $vms } 
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'VisualStudio2013' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'VisualStudio2015' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'Office2013' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { -not $_.Roles.Name -and $_ -notin $vms }

            #$vms = $vms | Select-Object *, @{name='OSversion';expression={$_.OperatingSystem.Version}} | Sort-Object -Property OSversion
            $vms = $vms | Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -ne 'Started' } | Select-Object -First $StartNextMachines

            if ($Domain)
            {
                $vms = $vms | Where-Object { (Get-LabMachine -ComputerName $_) -eq $Domain }
            }
        }
        elseif (-not ($PSCmdlet.ParameterSetName -eq 'ByRole') -and -not $RootDomainMachines -and $StartNextMachines -and -not $StartNextDomainControllers)
        {
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -like 'SqlServer*' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'WebServer' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'Orchestrator' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'Exchange2013' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'Exchange2016' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'VisualStudio2013' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'VisualStudio2015' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'Office2013' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { -not $_.Roles.Name -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'CaRoot' -and $_ -notin $vms }
            $vms += Get-LabMachine | Where-Object { $_.Roles.Name -eq 'CaSubordinate' -and $_ -notin $vms }

            $vms = $vms | Select-Object *, @{name='OSversion';expression={$_.OperatingSystem.Version}} | Sort-Object -Property OSversion
            $vms = $vms | Where-Object { (Get-LabVMStatus -ComputerName $_.Name) -ne 'Started' } | Select-Object -First $StartNextMachines

            if ($Domain)
            {
                $vms = $vms | Where-Object { (Get-LabMachine -ComputerName $_) -eq $Domain }
            }
        }
        elseif (-not ($PSCmdlet.ParameterSetName -eq 'ByRole') -and $RootDomainMachines -and -not $StartNextDomainControllers)
        {
            $vms = Get-LabMachine | Where-Object { $_.DomainName -in (Get-LabMachine -Role RootDC).DomainName } | Where-Object { $_.Name -notin (Get-LabMachine -Role RootDC).Name -and $_.Roles.Name -notlike '*DC' }
            $vms = $vms | Select-Object *, @{name='OSversion';expression={$_.OperatingSystem.Version}} | Sort-Object -Property OSversion
            $vms = $vms | Select-Object -First $StartNextMachines
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $vms = $availableVMs
        }
    }
    
    end
    {
        #if there are no VMs to start, just write a warning
        if (-not $vms)
        {
            return
        }

        $vmsCopy = $vms

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
        
        Write-Verbose "Starting VMs '$($vms.Name -join ', ')'"
        
        $hypervVMs = $vms | Where-Object HostType -eq 'HyperV'
        if ($hypervVMs)
        {
            Start-LWHypervVM -ComputerName $hypervVMs -DelayBetweenComputers $DelayBetweenComputers -ProgressIndicator $ProgressIndicator -PreDelaySeconds $PreDelaySeconds -PostDelaySeconds $PostDelaySeconds -NoNewLine:$NoNewline
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

        if ($Wait)
        {
            Wait-LabVM -ComputerName ($vmsCopy) -Timeout $TimeoutInMinutes -DoNotUseCredSsp:$DoNotUseCredSsp -ProgressIndicator $ProgressIndicator -NoNewLine
        }
        
        if ($ProgressIndicator -and (-not $NoNewline))
        {
            Write-ProgressIndicatorEnd
        }

        Write-LogFunctionExit
    }
}
#endregion Start-LabVM

#region Save-LabVM
function Save-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    
    [cmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByName', Position = 0)]
        [string[]]$Name,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByRole')]
        [AutomatedLab.Roles]$RoleName,
        
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'All')]
        [switch]$All
    )
    
    begin
    {
        Write-LogFunctionEntry
        
        $lab = Get-Lab
        
        $vms = @()
        $availableVMs = $lab.Machines.Name
    }
    
    process
    {
        
        if (-not $lab.Machines)
        {
            $message = 'No machine definitions imported, please use Import-Lab first'
            Write-Error -Message $message
            Write-LogFunctionExitWithError -Message $message
            return
        }
        
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Name | ForEach-Object {
                if ($_ -in $availableVMs)
                {
                    $vms += $_
                }
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'ByRole')
        {
            #get all machines that have a role assigned and the machine's role name is part of the parameter RoleName
            $machines = ($lab.Machines |
                Where-Object { $_.Roles.Name } |
            Where-Object { $_.Roles | Where-Object { $RoleName.HasFlag([AutomatedLab.Roles]$_.Name) } }).Name
            $vms = $machines
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $vms = $availableVMs
        }
    }
    
    end
    {
        $vms = Get-LabMachine -ComputerName $vms
        
        #if there are no VMs to start, just write a warning
        if (-not $vms)
        {
            Write-Warning 'There is no machine to start'
            return
        }
        
        foreach ($vm in $vms)
        {
            Write-Verbose "Saving VMs '$vm'"
            
            if ($vm.HostType -eq 'HyperV')
            {
                Save-LWHypervVM -ComputerName $vm
            }
            elseif ($vm.HostType -eq 'Azure')
            {
                Write-Error 'Azure does not support saving machines'
            }
            elseif ($vm.HostType -eq 'VMWare')
            {
                Save-LWVMWareVM -ComputerName $vm
            }
        }
        
        Write-LogFunctionExit
    }
}
#endregion Start-LabVM

#region Restart-LabVM
function Restart-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,
        
        [switch]$Wait,
        
        [double]$ShutdownTimeoutInMinutes = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_RestartLabMachine_Shutdown,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )
    
    Write-LogFunctionEntry
    
    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    $machines = Get-LabMachine -ComputerName $ComputerName
    
    if (-not $machines)
    {
        Write-Error "The machines '$($ComputerName -join ', ')' could not be found in the lab."
        return
    }
    
    Write-Verbose "Stopping machine '$ComputerName' and waiting for shutdown"
    Stop-LabVM -ComputerName $ComputerName -ShutdownTimeoutInMinutes $ShutdownTimeoutInMinutes -Wait -ProgressIndicator $ProgressIndicator -NoNewLine
    Write-Verbose "Machine '$ComputerName' is stopped"

    Write-Debug 'Waiting 10 seconds'
    Start-Sleep -Seconds 10
    
    Write-Verbose "Starting machine '$ComputerName' and waiting for availability"
    Start-LabVM -ComputerName $ComputerName -Wait:$Wait -ProgressIndicator $ProgressIndicator -NoNewline:$NoNewLine
    Write-Verbose "Machine '$ComputerName' is started"	

    Write-LogFunctionExit
}
#endregion Restart-LabVM

#region Stop-LabVM
function Stop-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string[]]$ComputerName,
        
        [double]$ShutdownTimeoutInMinutes = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_StopLabMachine_Shutdown,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All,
        
        [switch]$Wait,

        [int]$ProgressIndicator,

        [switch]$NoNewLine
    )
    
    Write-LogFunctionEntry
    
    $lab = Get-Lab
    if (-not $lab.Machines)
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    if ($ComputerName)
    {
        $machines = Get-LabMachine -ComputerName $ComputerName
    }
    elseif ($All)
    {
        $machines = Get-LabMachine
    }

    #filtering out all machines that are already stopped
    $vmStates = Get-LabVMStatus -ComputerName $machines -AsHashTable
    foreach ($vmState in $vmStates.GetEnumerator())
    {
        if ($vmState.Value -eq 'Stopped')
        {
            $machines = $machines | Where-Object Name -ne $vmState.Name
            Write-Debug "Machine $($vmState.Name) is already stopped, removing it from the list of machines to stop"
        }
    }
    
    Remove-LabPSSession -ComputerName $machines
    
    $hypervVms = $machines | Where-Object HostType -eq 'HyperV'
    $azureVms = $machines | Where-Object HostType -eq 'Azure'
    $vmwareVms = $machines | Where-Object HostType -eq 'VMWare'
    
    if ($hypervVms) { Stop-LWHypervVM -ComputerName $hypervVms -TimeoutInMinutes $ShutdownTimeoutInMinutes -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine -ErrorVariable hypervErrors -ErrorAction SilentlyContinue }
    if ($azureVms) { Stop-LWAzureVM -ComputerName $azureVms -ErrorVariable azureErrors -ErrorAction SilentlyContinue }
    if ($vmwareVms) { Stop-LWVMWareVM -ComputerName $vmwareVms -ErrorVariable vmwareErrors -ErrorAction SilentlyContinue }
    
    $remainingTargets = @()
    if ($hypervErrors) { $remainingTargets += $hypervErrors.TargetObject }
    if ($azureErrors) { $remainingTargets + $azureErrors.TargetObject }
    if ($vmwareErrors) { $remainingTargets + $vmwareErrors.TargetObject }
    if ($remainingTargets) { Stop-LabVM2 -ComputerName $remainingTargets }
    
    if ($Wait)
    {
        Wait-LabVMShutdown -ComputerName $machines -TimeoutInMinutes $ShutdownTimeoutInMinutes
    }
    
    Write-LogFunctionExit
}
#endregion Stop-LabVM

#region Stop-LabVM2
function Stop-LabVM2
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string[]]$ComputerName,
        
        [int]$ShutdownTimeoutInMinutes = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_StopLabMachine_Shutdown
    )
    
    $scriptBlock = {
        $sessions = quser.exe
        $sessionNames = $sessions |
        Select-Object -Skip 1 |
        ForEach-Object -Process {
            ($_.Trim() -split ' +')[2]
        }
        
        Write-Verbose -Message "There are $($sessionNames.Count) open sessions"
        foreach ($sessionName in $sessionNames)
        {
            Write-Verbose -Message "Closing session '$sessionName'"
            logoff.exe $sessionName
        }
        
        Start-Sleep -Seconds 2
        
        Write-Verbose -Message 'Stopping machine forcefully'
        Stop-Computer -Force
    }
    
    $jobs = Invoke-LabCommand -ComputerName $ComputerName -ActivityName Shutdown -NoDisplay -ScriptBlock $scriptBlock -AsJob -PassThru
    $jobs | Wait-Job -Timeout ($ShutdownTimeoutInMinutes * 60) | Out-Null
    
    if ($jobs.Count -ne ($jobs | Where-Object State -eq Completed).Count)
    {
        Write-Warning "Not all machines stopped in the timeout of $ShutdownTimeoutInMinutes"
    }
}
#endregion Stop-LabVM2

#region Wait-LabVM
function Wait-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,
        
        [double]$TimeoutInMinutes = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_WaitLabMachine_Online,

        [int]$PostDelaySeconds = 0,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = 0,
        
        [switch]$DoNotUseCredSsp,

        [switch]$NoNewLine
    )
    
    Write-LogFunctionEntry
        
    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
        
    $jobs = @()
    
    $vms = Get-LabMachine -ComputerName $ComputerName
    
    if (-not $vms)
    {
        Write-Error 'None of the given machines could be found'
        return
    }
        
    foreach ($vm in $vms)
    {
        $session = $null
        #remove the existing sessions to ensure a new one is created and the existing one not reused.
        Remove-LabPSSession -ComputerName $vm
            
        netsh.exe interface ip delete arpcache | Out-Null
        
        #if called without using DoNotUseCredSsp and the machine is not yet configured for CredSsp, call Wait-LabVM again but with DoNotUseCredSsp. Wait-LabVM enables CredSsp if called with DoNotUseCredSsp switch.
        $machineMetadata = Get-LWHypervVMDescription -ComputerName $vm
        if (($machineMetadata.InitState -band [AutomatedLab.LabVMInitState]::EnabledCredSsp) -ne [AutomatedLab.LabVMInitState]::EnabledCredSsp -and -not $DoNotUseCredSsp)
        {
            Wait-LabVM -ComputerName $vm -TimeoutInMinutes $TimeoutInMinutes -PostDelaySeconds $PostDelaySeconds -ProgressIndicator $ProgressIndicator -DoNotUseCredSsp -NoNewLine:$NoNewLine
        }
 
        $session = New-LabPSSession -ComputerName $vm -UseLocalCredential -Retries 1 -DoNotUseCredSsp:$DoNotUseCredSsp -ErrorAction SilentlyContinue
            
        if ($session)
        {
            Write-Verbose "Computer '$vm' was reachable"
            $jobs += Start-Job -Name "Waiting for machine '$vm'" -ScriptBlock {
                param (
                    [string]$ComputerName
                )
                        
                $ComputerName
            } -ArgumentList $vm.Name
        }
        else
        {
            Write-Verbose "Computer '$($vm.ComputerName)' was not reachable, waiting..."
            $jobs += Start-Job -Name "Waiting for machine '$vm'" -ScriptBlock {
                param(
                    [byte[]]$LabBytes,

                    [string]$ComputerName,
                        
                    [bool]$DoNotUseCredSsp
                )

                $VerbosePreference = $using:VerbosePreference

                Import-Module -Name Azure* -ErrorAction SilentlyContinue
                Write-Verbose "Importing Lab from $($LabBytes.Count) bytes"
                Import-Lab -LabBytes $LabBytes

                #do 5000 retries. This job is cancelled anyway if the timeout is reached
                Write-Verbose "Trying to create session to '$ComputerName'"
                $session = New-LabPSSession -ComputerName $ComputerName -UseLocalCredential  -Retries 5000 -DoNotUseCredSsp:$DoNotUseCredSsp

                return $ComputerName
            } -ArgumentList $lab.Export(), $vm.Name, $DoNotUseCredSsp
        }
    }

    Write-Verbose "Waiting for $($jobs.Count) machines to respond in timeout ($TimeoutInMinutes minute(s))"
        
    Wait-LWLabJob -Job $jobs -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine -NoDisplay
        
    $completed = $jobs | Where-Object State -eq Completed | Receive-Job -ErrorAction SilentlyContinue -Verbose:$VerbosePreference
        
    if ($completed)
    {
        $notReadyMachines = (Compare-Object -ReferenceObject $completed -DifferenceObject $vms.Name).InputObject
        $jobs | Remove-Job -Force
    }
    else
    {
        $notReadyMachines = $vms.Name
    }
        
    if ($notReadyMachines)
    {
        $message = "The following machines are not ready: $($notReadyMachines -join ', ')"
        Write-LogFunctionExitWithError -Message $message
    }
    else
    {
        Write-Verbose "The following machines are ready: $($completed -join ', ')"
            
        foreach ($machine in $completed)
        {
            if ((Get-LabVM -ComputerName $machine).HostType -eq 'HyperV')
            {
                $machineMetadata = Get-LWHypervVMDescription -ComputerName $machine
                if ($machineMetadata.InitState -eq [AutomatedLab.LabVMInitState]::Uninitialized)
                {
                    $machineMetadata.InitState = [AutomatedLab.LabVMInitState]::ReachedByAutomatedLab
                    Set-LWHypervVMDescription -Hashtable $machineMetadata -ComputerName $machine
                }

                if ($DoNotUseCredSsp -and ($machineMetadata.InitState -band [AutomatedLab.LabVMInitState]::EnabledCredSsp) -ne [AutomatedLab.LabVMInitState]::EnabledCredSsp)
                {
                    $credSspEnabled = Invoke-LabCommand -ComputerName $machine -ScriptBlock {

                        if ($PSVersionTable.PSVersion.Major -eq 2)
                        {
                            $d = "{0:HH:mm}" -f (Get-Date).AddMinutes(1)
                            $jobName = "AL_EnableCredSsp"
                            $Path = 'PowerShell'
                            $CommandLine = '-Command Enable-WSManCredSSP -Role Server -Force; Get-WSManCredSSP | Out-File -FilePath C:\EnableCredSsp.txt'
                            schtasks.exe /Create /SC ONCE /ST $d /TN $jobName /TR "$Path $CommandLine" | Out-Null
                            schtasks.exe /Run /TN $jobName | Out-Null
                            Start-Sleep -Seconds 1
                            while ((schtasks.exe /Query /TN $jobName) -like '*Running*')
                            {
                                Write-Host '.' -NoNewline
                                Start-Sleep -Seconds 1
                            }
                            Start-Sleep -Seconds 1
                            schtasks.exe /Delete /TN $jobName /F | Out-Null

                            Start-Sleep -Seconds 5
                                
                            [bool](Get-Content -Path C:\EnableCredSsp.txt | Where-Object { $_ -eq 'This computer is configured to receive credentials from a remote client computer.' })
                        }
                        else
                        {
                            Enable-WSManCredSSP -Role Server -Force | Out-Null
                            [bool](Get-WSManCredSSP | Where-Object { $_ -eq 'This computer is configured to receive credentials from a remote client computer.' })
                        }

                            
                    } -PassThru -DoNotUseCredSsp -NoDisplay
                        
                    if ($credSspEnabled)
                    {
                        $machineMetadata.InitState = $machineMetadata.InitState -bor [AutomatedLab.LabVMInitState]::EnabledCredSsp
                    }
                    else
                    {
                        Write-ScreenInfo "CredSsp could not be enabled on machine '$machine'" -Type Warning
                    }
                    
                    Set-LWHypervVMDescription -Hashtable $machineMetadata -ComputerName $machine
                }
            }
        }
            
        Write-LogFunctionExit
    }
    
    if ($PostDelaySeconds)
    {
        $job = Start-Job -Name "Wait $PostDelaySeconds seconds" -ScriptBlock { Start-Sleep -Seconds $Using:PostDelaySeconds }
        Wait-LWLabJob -Job $job -ProgressIndicator $ProgressIndicator -NoDisplay -NoNewLine:$NoNewLine
    }
}
#endregion Wait-LabVM

function Wait-LabVMRestart
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [switch]$DoNotUseCredSsp,
        
        [double]$TimeoutInMinutes = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_WaitLabMachine_Online,
        
        [ValidateRange(1, 300)]
        [int]$ProgressIndicator = 10,
        
        [AutomatedLab.Machine[]]$StartMachinesWhileWaiting,
        
        [switch]$NoNewLine,
        
        $MonitorJob
    )
    
    Write-LogFunctionEntry
    
    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    $vms = Get-LabMachine -ComputerName $ComputerName
    
    $azureVms = $vms | Where-Object HostType -eq 'Azure'
    $hypervVms = $vms | Where-Object HostType -eq 'HyperV'
    $vmwareVms = $vms | Where-Object HostType -eq 'VMWare'
    $start = Get-Date
    
    if ($azureVms)
    {
        Wait-LWAzureRestartVM -ComputerName $azureVms -DoNotUseCredSsp:$DoNotUseCredSsp -TimeoutInMinutes $TimeoutInMinutes `
        -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine -ErrorAction SilentlyContinue -ErrorVariable azureWaitError
    }

    if ($hypervVms)
    {
        Wait-LWHypervVMRestart -ComputerName $hypervVms -TimeoutInMinutes $TimeoutInMinutes -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine -StartMachinesWhileWaiting $StartMachinesWhileWaiting -ErrorAction SilentlyContinue -ErrorVariable hypervWaitError -MonitorJob $MonitorJob
    }
    
    if ($vmwareVms)
    {
        Wait-LWVMWareRestartVM -ComputerName $vmwareVms -TimeoutInMinutes $TimeoutInMinutes -ProgressIndicator $ProgressIndicator -ErrorAction SilentlyContinue -ErrorVariable vmwareWaitError
    }
    
    $waitError = New-Object System.Collections.ArrayList
    if ($azureWaitError) { $waitError.AddRange($azureWaitError) }
    if ($hypervWaitError) { $waitError.AddRange($hypervWaitError) }
    if ($vmwareWaitError) { $waitError.AddRange($vmwareWaitError) }
    
    $waitError = $waitError | Where-Object { $_.Exception.Message -like 'Timeout while waiting for computers to restart*' }
    if ($waitError)
    {
        $nonRestartedMachines = $waitError.TargetObject
        
        Write-Error "The following machines have not restarted in the timeout of $TimeoutInMinutes minute(s): $($nonRestartedMachines -join ', ')"
    }
    
    Write-LogFunctionExit
}
#endregion Wait-LabVMRestart

#region Wait-LabVMShutdown
function Wait-LabVMShutdown
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,
        
        [double]$TimeoutInMinutes = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.Timeout_WaitLabMachine_Online
    )
    
    Write-LogFunctionEntry

    $start = Get-Date
    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    $vms = Get-LabMachine -ComputerName $ComputerName
    
    $vms | Add-Member -Name HasShutdown -MemberType NoteProperty -Value $false -Force
    
    do
    {
        foreach ($vm in $vms)
        {
            $status = Get-LabVMStatus -ComputerName $vm -Verbose:$false
            
            if ($status -eq 'Stopped')
            {
                $vm.HasShutdown = $true
            }
            
            Start-Sleep -Seconds 5
        }
    }
    until (($vms | Where-Object { $_.HasShutdown }).Count -eq $vms.Count -or (Get-Date).AddMinutes(- $TimeoutInMinutes) -gt $start)
    
    foreach ($vm in ($vms | Where-Object { -not $_.HasShutdown }))
    {
        Write-Error -Message "Timeout while waiting for computer '$($vm.Name)' to shutdown." -TargetObject $vm.Name -ErrorVariable shutdownError
    }
    
    if ($shutdownError)
    {
        Write-Error "The following machines have not shutdown in the timeout of $TimeoutInMinutes minute(s): $($shutdownError.TargetObject -join ', ')"
    }
    
    Write-LogFunctionExit
}
#endregion Wait-LabVMShutdown

#region Remove-LabVM
function Remove-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string[]]$Name,
        
        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )
    
    Write-LogFunctionEntry
    
    $lab = Get-Lab
    if (-not $lab)
    {
        Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }
    
    if ($Name)
    {
        $machines = $lab.Machines | Where-Object Name -in $Name
    }
    else
    {
        $machines = $lab.Machines
    }
    
    if (-not $machines)
    {
        $message = 'No machine found to remove'
        Write-LogFunctionExitWithError -Message $message
        return
    }
    
    foreach ($machine in $machines)
    {
        $doNotUseGetHostEntry = $MyInvocation.MyCommand.Module.PrivateData.DoNotUseGetHostEntryInNewLabPSSession
        if (-not $doNotUseGetHostEntry)
        {
            $computerName = (Get-HostEntry -Hostname $machine).IpAddress.IpAddressToString
        }
       
        <#
                removed 161023, might not be required
                if ((Get-LabVMStatus -ComputerName $machine) -eq 'Unknown')
                {
                Start-LabVM -ComputerName $machines -Wait
        }#>
        
        Get-PSSession | Where-Object {$_.ComputerName -eq $computerName} | Remove-PSSession
        
        Write-ScreenInfo -Message "Removing Lab VM '$($machine.Name)' (and its associated disks)"
        
        if ($virtualNetworkAdapter.HostType -eq 'VMWare')
        {
            Write-Error 'Managing networks is not yet supported for VMWare'
            continue
        }
        
        if ($machine.HostType -eq 'HyperV')
        {
            Remove-LWHypervVM -Name $machine
        }
        elseif ($machine.HostType -eq 'Azure')
        {
            Remove-LWAzureVM -Name $machine
        }
        elseif ($machine.HostType -eq 'VMWare')
        {
            Remove-LWVMWareVM -Name $machine
        }
        
        if ((Get-HostEntry -Section (Get-Lab).Name.ToLower() -HostName $machine))
        {
            Remove-HostEntry -Section (Get-Lab).Name.ToLower() -HostName $machine
        }
        
        Write-ScreenInfo -Message "Lab VM '$machine' has been removed"
    }
}
#endregion Remove-LabVM

#region Get-LabVMStatus
function Get-LabVMStatus
{
    [cmdletBinding()]
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [string[]]$ComputerName,

        [switch]$AsHashTable
    )
    
    Write-LogFunctionEntry
    
    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if ($ComputerName)
    {
        $vms = Get-LabMachine -ComputerName $ComputerName
    }
    else
    {
        $vms = Get-LabMachine
    }
    
    $hypervVMs = $vms | Where-Object HostType -eq 'HyperV'
    if ($hypervVMs) { $hypervStatus = Get-LWHypervVMStatus -ComputerName $hypervVMs.Name }
    
    $azureVMs = $vms | Where-Object HostType -eq 'Azure'
    if ($azureVMs) { $azureStatus = Get-LWAzureVMStatus -ComputerName $azureVMs.Name }
    
    $vmwareVMs = $vms | Where-Object HostType -eq 'VMWare'
    if ($vmwareVMs) { $vmwareStatus = Get-LWVMWareVMStatus -ComputerName $vmwareVMs.Name }
    
    $result = @{ }
    if ($hypervStatus) { $result = $result + $hypervStatus }
    if ($azureStatus) { $result = $result + $azureStatus }
    if ($vmwareStatus) { $result = $result + $vmwareStatus }
    
    if ($result.Count -eq 1 -and -not $AsHashTable)
    {
        $result.Values[0]
    }
    else
    {
        $result
    }
    
    Write-LogFunctionExit
}
#endregion Get-LabVMStatus

#region Get-LabVMUptime
function Get-LabVMUptime
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )
    
    Write-LogFunctionEntry
    
    $cmdGetUptime = {
        $lastboottime = (Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime
        (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($lastboottime)
    }
    
    $uptime = Invoke-LabCommand -ComputerName $ComputerName -ActivityName GetUptime -ScriptBlock $cmdGetUptime -UseLocalCredential -PassThru
    
    if ($uptime)
    {
        Write-LogFunctionExit -ReturnValue $uptime
        $uptime
    }
    else
    {
        Write-LogFunctionExitWithError -Message 'Uptime could not be retrieved'
    }
}
#endregion Get-LabVMUptime

#region Connect-LabVM
function Connect-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [switch]$UseLocalCredential
    )
    
    $machines = Get-LabMachine -ComputerName $ComputerName
    $lab = Get-Lab
    
    foreach ($machine in $machines)
    {
        if ($UseLocalCredential)
        {
            $cred = $machine.GetLocalCredential()
        }
        else
        {
            $cred = $machine.GetCredential($lab)
        }
        
        if ($machine.HostType = 'Azure')
        {
            $cn = Get-LWAzureVMConnectionInfo -ComputerName $machine
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $cn.DnsName, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null
            mstsc.exe "/v:$($cn.DnsName):$($cn.RdpPort)"
            
            Start-Sleep -Seconds 5 #otherwise credentials get deleted too quickly
            
            $cmd = 'cmdkey /delete:TERMSRV/"{0}"' -f $cn.DnsName
            Invoke-Expression $cmd | Out-Null
        }
        elseif ($machine.HostType -eq 'HyperV')
        {
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $machine.Name, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null
            mstsc.exe "/v:$($cn.DnsName):$($cn.RdpPort)"
            
            Start-Sleep -Seconds 1 #otherwise credentials get deleted too quickly
            
            $cmd = 'cmdkey /delete:TERMSRV/"{0}"' -f $cn.DnsName
            Invoke-Expression $cmd | Out-Null
        }
    }
}
#endregion Connect-LabVM

#region Get-LabVMRdpFile
function Get-LabVMRdpFile
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,
        
        [switch]$UseLocalCredential,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )
    
    if ($ComputerName)
    {
        $machines = Get-LabMachine -ComputerName $ComputerName
    }
    else
    {
        $machines = Get-LabMachine -All
    }

    $lab = Get-Lab
    
    foreach ($machine in $machines)
    {
        Write-Verbose "Creating RDP file for machine '$($machine.Name)'"
        $port = 3389
        $name = $machine.Name

        if ($UseLocalCredential)
        {
            $cred = $machine.GetLocalCredential()
        }
        else
        {
            $cred = $machine.GetCredential($lab)
        }
        
        if ($machine.HostType = 'Azure')
        {
            $cn = Get-LWAzureVMConnectionInfo -ComputerName $machine.Name
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $cn.DnsName, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null

            $name = $cn.DnsName
            $port = $cn.RdpPort
        }
        elseif ($machine.HostType -eq 'HyperV')
        {
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $machine.Name, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null
        }

        $rdpContent = @"
redirectclipboard:i:1
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
devicestoredirect:s:*
drivestoredirect:s:*
redirectdrives:i:1
session bpp:i:32
prompt for credentials on client:i:0
span monitors:i:1
use multimon:i:0
server port:i:$port
allow font smoothing:i:1
promptcredentialonce:i:0
videoplaybackmode:i:1
audiocapturemode:i:1
gatewayusagemethod:i:0
gatewayprofileusagemethod:i:1
gatewaycredentialssource:i:0
full address:s:$name
use redirection server name:i:1
username:s:$($cred.UserName)
authentication level:i:0
"@
        $path = Join-Path -Path $lab.LabPath -ChildPath ($machine.Name + '.rdp')
        $rdpContent | Out-File -FilePath $path
        Write-Verbose "RDP file saved to '$path'"
    }
}
#endregion Get-LabVMRdpFile

#region Join-LabVMDomain
function Join-LabVMDomain
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]

    param(
        [Parameter(Mandatory, Position = 0)]
        [AutomatedLab.Machine[]]$Machine
    )

    Write-LogFunctionEntry

    #region Join-Computer
    function Join-Computer
    {
        [cmdletBinding()]

        param(
            [Parameter(Mandatory = $true)]
            [string]$DomainName,

            [Parameter(Mandatory = $true)]
            [System.Management.Automation.PSCredential]$Credential
        )

        Add-Computer -DomainName $DomainName -Credential $Credential -ErrorAction Stop

        $logonName = "$DomainName\$($Credential.UserName)"
        $password = $Credential.GetNetworkCredential().Password

        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1 -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value $logonName -Force | Out-Null
        New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value $password -Force | Out-Null

        Start-Sleep -Seconds 1

        Restart-Computer -Force
    }
    #endregion

    $lab = Get-Lab
    $jobs = @()

    Write-Verbose "Starting joining $($Machine.Count) machines to domains"
    foreach ($m in $Machine)
    {
        if ($m.OperatingSystem.Installation -eq 'Nano Server')
        {
            $temp = [System.IO.Path]::GetTempFileName()
            $dc = Get-LabMachine -Role ADDS | Where-Object DomainName -eq $m.DomainName            
            Remove-Item -Path $temp
            
            Invoke-LabCommand -ComputerName $dc -ScriptBlock {
                djoin /provision /domain $m.DomainName /machine $m.Name /savefile "C:\join_$($m.Name).txt"
            } -Variable (Get-Variable -Name m) -NoDisplay
            
            Receive-File -Source "C:\join_$($m.Name).txt" -Destination $temp -Session (Get-LabPSSession -ComputerName $dc)
            Copy-LabFileItem -Path $temp -ComputerName $m
            
            Invoke-LabCommand -ActivityName "Offline Domain Join on '$m'" -ComputerName $m -ScriptBlock {
                djoin /requestodj /loadfile "C:\$([System.IO.Path]::GetFileName($temp))" /windowspath C:\Windows /localos
            } -Variable (Get-Variable -Name temp) -NoDisplay
            
            Remove-Item -Path $temp
        }
        else
        {
            $domain = $lab.Domains | Where-Object Name -eq $m.DomainName
            $cred = $domain.GetCredential()

            Write-Verbose "Joining machine '$m' to domain '$domain'"
            $jobs += Invoke-LabCommand -ComputerName $m -ActivityName DomainJoin -ScriptBlock (Get-Command Join-Computer).ScriptBlock `
            -UseLocalCredential -ArgumentList $domain, $cred -AsJob -PassThru -NoDisplay
        }
    }
    
    if ($jobs) #not for Nano Servers
    {
        Write-Verbose 'Waiting on jobs to finish'
        Wait-LWLabJob -Job $jobs -ProgressIndicator 15 -NoDisplay -NoNewLine
    
        Write-ProgressIndicatorEnd
        Write-ScreenInfo -Message 'Waiting for machines to restart' -NoNewLine
        Wait-LabVMRestart -ComputerName $Machine -ProgressIndicator 30 -NoNewLine
    }
    
    foreach ($m in $Machine)
    {
        $m.HasDomainJoined = $true
    }
    Export-Lab
    
    Write-LogFunctionExit
}
#endregion Join-LabVMDomain

#region Mount-LabIsoImage
function Mount-LabIsoImage
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, Position = 1)]
        [string]$IsoPath,

        [switch]$SupressOutput,
        
        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $machines = Get-LabMachine -ComputerName $ComputerName

    $machines | Where-Object HostType -notin HyperV,Azure | ForEach-Object {
        Write-Warning "Using ISO images is only supported with Hyper-V VMs or on Azure. Skipping machine '$($_.Name)'"
    }

    $machines = $machines | Where-Object HostType -in HyperV,Azure

    foreach ($machine in $machines)
    {
        if (-not $SupressOutput)
        {
            Write-ScreenInfo -Message "Mounting ISO image '$IsoPath' to computer '$machine'" -Type Info
        }
        
        if ($machine.HostType -eq 'HyperV')
        {
            Mount-LWIsoImage -ComputerName $machine -IsoPath $IsoPath -PassThru:$PassThru
        }
        else 
        {
            Mount-LWAzureIsoImage -ComputerName $machine -IsoPath $IsoPath -PassThru:$PassThru
        }
    }

    Write-LogFunctionExit
}
#endregion Mount-LabIsoImage

#region Dismount-LabIsoImage
function Dismount-LabIsoImage
{
    # .ExternalHelp AutomatedLab.Help.xml
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName,
        
        [switch]$SupressOutput
    )

    Write-LogFunctionEntry

    $machines = Get-LabMachine -ComputerName $ComputerName

    $machines | Where-Object HostType -ne HyperV | ForEach-Object {
        Write-Warning "Using ISO images is only supported with Hyper-V VMs. Skipping machine '$($_.Name)'"
    }

    $machines = $machines | Where-Object HostType -eq HyperV

    foreach ($machine in $machines)
    {
        if (-not $SupressOutput)
        {
            Write-ScreenInfo -Message "Dismounting currently mounted ISO image on computer '$machine'." -Type Info
        }
        
        Dismount-LWIsoImage -ComputerName $machine
    }

    Write-LogFunctionExit
}
#endregion Dismount-LabIsoImage

#region Get / Set-LabMachineUacStatus
function Set-MachineUacStatus
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]
    param(        
        [bool]$EnableLUA,
        
        [int]$ConsentPromptBehaviorAdmin,
        
        [int]$ConsentPromptBehaviorUser
    )
    
    $currentSettings = Get-MachineUacStatus -ComputerName $ComputerName
    $uacStatusChanges = $false
    
    $registryPath = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'
    $openRegistry = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, 'Default')
    
    $subkey = $openRegistry.OpenSubKey($registryPath,$true)
    
    if ($currentSettings.EnableLUA -ne $EnableLUA -and $PSBoundParameters.ContainsKey('EnableLUA'))
    {
        $subkey.SetValue('EnableLUA', [int]$EnableLUA)
        $uacStatusChanges = $true
    }
    
    if ($currentSettings.PromptBehaviorAdmin -ne $ConsentPromptBehaviorAdmin -and $PSBoundParameters.ContainsKey('ConsentPromptBehaviorAdmin'))
    {
        $subkey.SetValue('ConsentPromptBehaviorAdmin', $ConsentPromptBehaviorAdmin)
        $uacStatusChanges = $true
    }
    
    if ($currentSettings.PromptBehaviorUser -ne $ConsentPromptBehaviorUser -and $PSBoundParameters.ContainsKey('ConsentPromptBehaviorUser'))
    {
        $subkey.SetValue('ConsentPromptBehaviorUser', $ConsentPromptBehaviorUser)
        $uacStatusChanges = $true
    }

    if ($uacStatusChanges)
    {
        Write-Warning "Setting this requires a reboot of $ComputerName."
    }
}

function Get-MachineUacStatus
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )
    
    $registryPath = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'
    $uacStatus = $false
    
    $openRegistry = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, 'Default')
    $subkey = $openRegistry.OpenSubKey($registryPath, $false)
    
    $uacStatus = $subkey.GetValue('EnableLUA')
    $consentPromptBehaviorUser = $subkey.GetValue('ConsentPromptBehaviorUser')
    $consentPromptBehaviorAdmin = $subkey.GetValue('ConsentPromptBehaviorAdmin')
    
    New-Object -TypeName PSObject -Property @{
        ComputerName = $ComputerName
        EnableLUA = $uacStatus
        PromptBehaviorUser = $consentPromptBehaviorUser
        PromptBehaviorAdmin = $consentPromptBehaviorAdmin
    }
}

function Set-LabMachineUacStatus
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [bool]$EnableLUA,
        
        [int]$ConsentPromptBehaviorAdmin,
        
        [int]$ConsentPromptBehaviorUser,
        
        [switch]$PassThru
    )

    Write-LogFunctionEntry
    
    $machines = Get-LabMachine -ComputerName $ComputerName
    
    if (-not $machines)
    {
        Write-Error 'The given machines could not be found'
        return
    }
    
    $functions = Get-Command -Name Get-MachineUacStatus, Set-MachineUacStatus, Sync-Parameter
    $variables = Get-Variable -Name PSBoundParameters
    Invoke-LabCommand -ActivityName 'Set Uac Status' -ComputerName $machines -ScriptBlock {
    
        Sync-Parameter -Command (Get-Command -Name Set-MachineUacStatus)
        Set-MachineUacStatus @ALBoundParameters
    
    } -Function $functions -Variable $variables

    if ($PassThru)
    {
        Get-LabMachineUacStatus -ComputerName $ComputerName
    }
    
    Write-LogFunctionExit
}

function Get-LabMachineUacStatus
{
    # .ExternalHelp AutomatedLab.Help.xml
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry
    
    $machines = Get-LabMachine -ComputerName $ComputerName
    
    if (-not $machines)
    {
        Write-Error 'The given machines could not be found'
        return
    }
    
    Invoke-LabCommand -ActivityName 'Get Uac Status' -ComputerName $machines -ScriptBlock {
        Get-MachineUacStatus
    } -Function (Get-Command -Name Get-MachineUacStatus) -PassThru

    Write-LogFunctionExit
}
#endregion Get / Set-LabMachineUacStatus

#region Test-LabMachineInternetConnectivity
function Test-LabMachineInternetConnectivity
{
    # .ExternalHelp AutomatedLab.Help.xml
    [OutputType([bool])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [int]$Count = 3,
        
        [switch]$AsJob
    )
    
    $cmd = {
        $result = 1..$Count | 
        ForEach-Object {
            Test-NetConnection www.microsoft.com -CommonTCPPort HTTP -InformationLevel Detailed -WarningAction SilentlyContinue
            Start-Sleep -Seconds 1
        }
            
        #if two results are positive, return the first positive result, if all are negative, return the first negative result
        if (($result.TcpTestSucceeded | Where-Object { $_ -eq $true }).Count -ge 2)
        {
            $result | Where-Object TcpTestSucceeded -eq $true | Select-Object -First 1
        }
        elseif (($result.TcpTestSucceeded | Where-Object { $_ -eq $false }).Count -eq 5)
        {
            $result | Where-Object TcpTestSucceeded -eq $false | Select-Object -First 1
        }
    }
    
    if ($AsJob)
    {
        $job = Invoke-LabCommand -ComputerName $ComputerName -ActivityName "Testing Internet Connectivity of '$ComputerName'" `
        -ScriptBlock $cmd -Variable (Get-Variable -Name Count) -PassThru -NoDisplay -AsJob
    
        return $job
    }
    else
    {
        $result = Invoke-LabCommand -ComputerName $ComputerName -ActivityName "Testing Internet Connectivity of '$ComputerName'" `
        -ScriptBlock $cmd -Variable (Get-Variable -Name Count) -PassThru -NoDisplay
    
        return $result.TcpTestSucceeded
    }
}
#endregion Test-LabMachineInternetConnectivity

#region Get-LabVM
function Get-LabVM
{
    # .ExternalHelp AutomatedLab.Help.xml 
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([AutomatedLab.Machine])]
    param (
        [Parameter(Position = 0, ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory, ParameterSetName = 'ByRole')]
        [AutomatedLab.Roles]$Role,
        
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,
        
        [switch]$IsRunning
    )
    
    begin
    {
        #required to suporess verbose messages, warnings and errors
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        Write-LogFunctionEntry
        
        $result = @()
        if (-not $script:data)
        {
            $script:data = Get-Lab
        }
    }
    
    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            if ($ComputerName)
            {
                foreach ($n in $ComputerName)
                {
                    $machine = $Script:data.Machines | Where-Object Name -in $n
                    if (-not $machine)
                    {
                        continue
                    }
                
                    $result += $machine
                }
            }
            else
            {
                $result = $Script:data.Machines
            }
        }
        
        if ($PSCmdlet.ParameterSetName -eq 'ByRole')
        {
            $result = $Script:data.Machines |
            Where-Object { $_.Roles.Name } |
            Where-Object { $_.Roles | Where-Object { $Role.HasFlag([AutomatedLab.Roles]$_.Name) } }
            
            if (-not $result)
            {
                return
            }
        }
        
        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $result = $Script:data.Machines
        }
    }
    
    end
    {
        #Add Azure Connection Info
        $azureVMs = $Script:data.Machines | Where-Object { $_.HostType -eq 'Azure' -and -not $_.AzureConnectionInfo.DnsName }
        if ($azureVMs)
        {
            $azureConnectionInfo = Get-LWAzureVMConnectionInfo -ComputerName $azureVMs

            if ($azureConnectionInfo)
            {
                foreach ($azureVM in $azureVMs)
                {
                    $azureVM | Add-Member -Name AzureConnectionInfo -MemberType NoteProperty -Value ($azureConnectionInfo | Where-Object ComputerName -eq $azureVM) -Force
                }
            }
        }

        if ($IsRunning)
        {
            if ($result.Count -eq 1)
            {
                if ((Get-LabVMStatus -ComputerName $result) -eq 'Started')
                {
                    $result
                }
            }
            else
            {
                $startedMachines = (Get-LabVMStatus -ComputerName $result).GetEnumerator() | Where-Object Value -eq 'Started'
                $Script:data.Machines | Where-Object { $_.Name -in $startedMachines.Name }
            }
        }
        else
        {
            $result
        }
    }
}
#endregion Get-LabVM

New-Alias -Name Get-LabMachine -Value Get-LabVM -Scope Global -Force