#region New-LabPSSession
function New-LabPSSession
{
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByMachine')]
        [AutomatedLab.Machine[]]$Machine,

        #this is used to recreate a broken session
        [Parameter(Mandatory, ParameterSetName = 'BySession')]
        [System.Management.Automation.Runspaces.PSSession]$Session,

        [switch]$UseLocalCredential,

        [switch]$DoNotUseCredSsp,

        [pscredential]$Credential,

        [int]$Retries = 2,

        [int]$Interval = 5,

        [switch]$UseSSL,

        [switch]$IgnoreAzureLabSources
    )

    begin
    {
        Write-LogFunctionEntry
        $sessions = @()
        $lab = Get-Lab

        #Due to a problem in Windows 10 not being able to reach VMs from the host
        if (-not ($IsLinux -or $IsMacOs)) { netsh.exe interface ip delete arpcache | Out-Null }
        $testPortTimeout = (Get-LabConfigurationItem -Name Timeout_TestPortInSeconds) * 1000
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Machine = Get-LabVM -ComputerName $ComputerName -IncludeLinux

            if (-not $Machine)
            {
                Write-Error "There is no computer with the name '$ComputerName' in the lab"
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'BySession')
        {
            $internalSession = $Session
            $Machine = Get-LabVM -ComputerName $internalSession.LabMachineName -IncludeLinux

            if ($internalSession.Runspace.ConnectionInfo.AuthenticationMechanism -ne 'Credssp')
            {
                $DoNotUseCredSsp = $true
            }
            if ($internalSession.Runspace.ConnectionInfo.Credential.UserName -like "$($Machine.Name)*")
            {
                $UseLocalCredential = $true
            }
        }

        foreach ($m in $Machine)
        {
            $machineRetries = $Retries

            if ($Credential)
            {
                $cred = $Credential
            }
            elseif ($UseLocalCredential -and ($IsLinux -and $m.IsDomainJoined -and -not $m.HasDomainJoined))
            {
                $cred = $m.GetLocalCredential($true)
            }
            elseif ($UseLocalCredential)
            {
                $cred = $m.GetLocalCredential()
            }
            elseif ($IsLinux -and $m.IsDomainJoined -and -not $m.HasDomainJoined)
            {
                $cred = $m.GetLocalCredential($true)
            }
            else
            {
                $cred = $m.GetCredential($lab)
            }

            $param = @{}
            $param.Add('Name', "$($m)_$([guid]::NewGuid())")
            $param.Add('Credential', $cred)
            $param.Add('UseSSL', $false)

            if ($DoNotUseCredSsp)
            {
                $param.Add('Authentication', 'Default')
            }
            else
            {
                $param.Add('Authentication', 'Credssp')
            }

            if ($m.HostType -eq 'Azure')
            {
                if (-not $m.AzureConnectionInfo.DnsName)
                {
                    $m.AzureConnectionInfo = Get-LWAzureVMConnectionInfo -ComputerName $m
                }

                $param.Add('ComputerName', $m.AzureConnectionInfo.DnsName)
                Write-PSFMessage "Azure DNS name for machine '$m' is '$($m.AzureConnectionInfo.DnsName)'"
                $param.Add('Port', $m.AzureConnectionInfo.Port)
                if ($UseSSL)
                {
                    $param.Add('SessionOption', (New-PSSessionOption -SkipCACheck -SkipCNCheck))
                    $param.UseSSL = $true
                }
            }
            elseif ($m.HostType -eq 'HyperV' -or $m.HostType -eq 'VMWare')
            {
                # DoNotUseGetHostEntryInNewLabPSSession is used when existing DNS is possible
                # SkipHostFileModification is used when the local hosts file should not be used
                $doNotUseGetHostEntry = Get-LabConfigurationItem -Name DoNotUseGetHostEntryInNewLabPSSession
                if (-not $doNotUseGetHostEntry)
                {
                    $name = (Get-HostEntry -Hostname $m).IpAddress.IpAddressToString
                }
                elseif (-not [string]::IsNullOrEmpty($m.FriendlyName) -or (Get-LabConfigurationItem -Name SkipHostFileModification))
                {
                    $name = $m.IpV4Address
                }

                if ($name)
                {
                    Write-PSFMessage "Connecting to machine '$m' using the IP address '$name'"
                    $param.Add('ComputerName', $name)
                }
                else
                {
                    Write-PSFMessage "Connecting to machine '$m' using the DNS name '$m'"
                    $param.Add('ComputerName', $m)
                }
                $param.Add('Port', 5985)
            }

            if ($m.OperatingSystemType -eq 'Linux')
            {
                Set-Item -Path WSMan:\localhost\Client\Auth\Basic -Value $true -Force
                $param['SessionOption'] = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
                $param['UseSSL'] = $true
                $param['Port'] = 5986
                $param['Authentication'] = 'Basic'
            }

            if ($IsLinux -or $IsMacOs)
            {
                $param['Authentication'] = 'Negotiate'
            }

            Write-PSFMessage ("Creating a new PSSession to machine '{0}:{1}' (UserName='{2}', Password='{3}', DoNotUseCredSsp='{4}')" -f $param.ComputerName, $param.Port, $cred.UserName, $cred.GetNetworkCredential().Password, $DoNotUseCredSsp)

            #session reuse. If there is a session to the machine available, return it, otherwise create a new session
            $internalSession = Get-PSSession | Where-Object {
                $_.ComputerName -eq $param.ComputerName -and
                $_.Runspace.ConnectionInfo.Port -eq $param.Port -and
                $_.Availability -eq 'Available' -and
                $_.Runspace.ConnectionInfo.AuthenticationMechanism -eq $param.Authentication -and
                $_.State -eq 'Opened' -and
                $_.Name -like "$($m)_*" -and
                $_.Runspace.ConnectionInfo.Credential.UserName -eq $param.Credential.UserName
            }

            if ($internalSession)
            {
                if ($internalSession.Runspace.ConnectionInfo.AuthenticationMechanism -eq 'CredSsp' -and
                    -not $IgnoreAzureLabSources.IsPresent -and -not $internalSession.ALLabSourcesMapped -and
                    (Get-LabVM -ComputerName $internalSession.LabMachineName).HostType -eq 'Azure'
                )
                {
                    #remove the existing session if connecting to Azure LabSource did not work in case the session connects to an Azure VM.
                    Write-ScreenInfo "Removing session to '$($internalSession.LabMachineName)' as ALLabSourcesMapped was false" -Type Warning
                    Remove-LabPSSession -ComputerName $internalSession.LabMachineName
                    $internalSession = $null
                }

                if ($internalSession.Count -eq 1)
                {
                    Write-PSFMessage "Session $($internalSession.Name) is available and will be reused"
                    $sessions += $internalSession
                }
                elseif ($internalSession.Count -ne 0)
                {
                    $sessionsToRemove = $internalSession | Select-Object -Skip (Get-LabConfigurationItem -Name MaxPSSessionsPerVM)
                    Write-PSFMessage "Found orphaned sessions. Removing $($sessionsToRemove.Count) sessions: $($sessionsToRemove.Name -join ', ')"
                    $sessionsToRemove | Remove-PSSession

                    Write-PSFMessage "Session $($internalSession[0].Name) is available and will be reused"
                    #Replaced Select-Object with array indexing because of https://github.com/PowerShell/PowerShell/issues/9185
                    $sessions += ($internalSession | Where-Object State -eq 'Opened')[0] #| Select-Object -First 1
                }
            }

            while (-not $internalSession -and $machineRetries -gt 0)
            {
                if (-not ($IsLinux -or $IsMacOs)) { netsh.exe interface ip delete arpcache | Out-Null }

                Write-PSFMessage "Testing port $($param.Port) on computer '$($param.ComputerName)'"
                $portTest = Test-Port -ComputerName $param.ComputerName -Port $param.Port -TCP -TcpTimeout $testPortTimeout
                if ($portTest.Open)
                {
                    Write-PSFMessage 'Port was open, trying to create the session'
                    $internalSession = New-PSSession @param -ErrorAction SilentlyContinue -ErrorVariable sessionError
                    $internalSession | Add-Member -Name LabMachineName -MemberType ScriptProperty -Value { $this.Name.Substring(0, $this.Name.IndexOf('_')) }

                    # Additional check here for availability/state due to issues with Azure IaaS
                    if ($internalSession -and $internalSession.Availability -eq 'Available' -and $internalSession.State -eq 'Opened')
                    {
                        Write-PSFMessage "Session to computer '$($param.ComputerName)' created"
                        $sessions += $internalSession

                        if ((Get-LabVM -ComputerName $internalSession.LabMachineName).HostType -eq 'Azure')
                        {
                            Connect-LWAzureLabSourcesDrive -Session $internalSession
                        }

                    }
                    else
                    {
                        Write-PSFMessage -Message "Session to computer '$($param.ComputerName)' could not be created, waiting $Interval seconds ($machineRetries retries). The error was: '$($sessionError[0].FullyQualifiedErrorId)'"
                        if ($Retries -gt 1) { Start-Sleep -Seconds $Interval }
                        $machineRetries--
                    }
                }
                else
                {
                    Write-PSFMessage 'Port was NOT open, cannot create session.'
                    Start-Sleep -Seconds $Interval
                    $machineRetries--
                }
            }

            if (-not $internalSession)
            {
                if ($sessionError.Count -gt 0)
                {
                    Write-Error -ErrorRecord $sessionError[0]
                }
                elseif ($machineRetries -lt 1)
                {
                    if (-not $portTest.Open)
                    {
                        Write-Error -Message "Could not create a session to machine '$m' as the port is closed after $Retries retries."
                    }
                    else
                    {
                        Write-Error -Message "Could not create a session to machine '$m' after $Retries retries."
                    }
                }
            }
        }
    }

    end
    {
        Write-LogFunctionExit -ReturnValue "Session IDs: $(($sessions.ID -join ', '))"
        $sessions
    }
}
#endregion New-LabPSSession

#region Get-LabPSSession
function Get-LabPSSession
{
    [cmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.PSSession])]

    param (
        [string[]]$ComputerName,

        [switch]$DoNotUseCredSsp
    )

    $pattern = '\w+_[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}'

    if ($ComputerName)
    {
        $computers = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }
    else
    {
        $computers = Get-LabVM -IncludeLinux
    }

    if (-not $computers)
    {
        Write-Error 'The machines could not be found' -TargetObject $ComputerName
    }

    $sessions = foreach ($computer in $computers)
    {
        $session = Get-PSSession | Where-Object { $_.Name -match $pattern -and $_.Name -like "$($computer.Name)_*" }

        if (-not $session -and $ComputerName)
        {
            Write-Error "No session found for computer '$computer'" -TargetObject $computer
        }
        else
        {
            $session
        }
    }

    if ($DoNotUseCredSsp)
    {
        $sessions | Where-Object { $_.Runspace.ConnectionInfo.AuthenticationMechanism -ne 'CredSsp' }
    }
    else
    {
        $sessions
    }
}
#endregion Get-LabPSSession

#region Remove-LabPSSession
function Remove-LabPSSession
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByMachine')]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $Machine = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }
    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $Machine = Get-LabVM -All -IncludeLinux
    }

    $sessions = foreach ($m in $Machine)
    {
        $param = @{}
        if ($m.HostType -eq 'Azure')
        {
            $param.Add('ComputerName', $m.AzureConnectionInfo.DnsName)
            $param.Add('Port', $m.AzureConnectionInfo.Port)
        }
        elseif ($m.HostType -eq 'HyperV' -or $m.HostType -eq 'VMWare')
        {
            if (Get-LabConfigurationItem -Name DoNotUseGetHostEntryInNewLabPSSession)
            {
                $param.Add('ComputerName', $m.Name)
            }
            elseif (-not [string]::IsNullOrEmpty($m.FriendlyName) -or (Get-LabConfigurationItem -Name SkipHostFileModification))
            {
                $param.Add('ComputerName', $m.IpV4Address)
            }
            else
            {
                $param.Add('ComputerName', (Get-HostEntry -Hostname $m).IpAddress.IpAddressToString)
            }
            $param.Add('Port', 5985)
        }

        Get-PSSession | Where-Object {
            $_.ComputerName -eq $param.ComputerName -and
            $_.Runspace.ConnectionInfo.Port -eq $param.Port -and
        $_.Name -like "$($m)_*" }
    }

    $sessions | Remove-PSSession -ErrorAction SilentlyContinue

    Write-PSFMessage "Removed $($sessions.Count) PSSessions..."
    Write-LogFunctionExit
}
#endregion Remove-LabPSSession

#region Enter-LabPSSession
function Enter-LabPSSession
{
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByMachine', Position = 0)]
        [AutomatedLab.Machine]$Machine,

        [switch]$DoNotUseCredSsp,

        [switch]$UseLocalCredential
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $Machine = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }

    if ($Machine)
    {
        $session = New-LabPSSession -Machine $Machine -DoNotUseCredSsp:$DoNotUseCredSsp -UseLocalCredential:$UseLocalCredential

        $session | Enter-PSSession
    }
    else
    {
        Write-Error 'The specified machine could not be found in the lab.'
    }
}
#endregion Enter-LabPSSession

#region Invoke-LabCommand
function Invoke-LabCommand
{
    [cmdletBinding()]
    param (
        [string]$ActivityName = '<unnamed>',

        [Parameter(Mandatory, ParameterSetName = 'ScriptBlockFileContentDependency', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'ScriptFileContentDependency', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'ScriptFileNameContentDependency', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'Script', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'PostInstallationActivity', Position = 0)]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ScriptBlockFileContentDependency', Position = 1)]
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock', Position = 1)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory, ParameterSetName = 'ScriptFileContentDependency')]
        [Parameter(Mandatory, ParameterSetName = 'Script')]
        [string]$FilePath,

        [Parameter(Mandatory, ParameterSetName = 'ScriptFileNameContentDependency')]
        [string]$FileName,

        [Parameter(ParameterSetName = 'ScriptFileNameContentDependency')]
        [Parameter(Mandatory, ParameterSetName = 'ScriptBlockFileContentDependency')]
        [Parameter(Mandatory, ParameterSetName = 'ScriptFileContentDependency')]
        [string]$DependencyFolderPath,

        [Parameter(ParameterSetName = 'PostInstallationActivity')]
        [switch]$PostInstallationActivity,

        [Parameter(ParameterSetName = 'PostInstallationActivity')]
        [string[]]$CustomRoleName,

        [object[]]$ArgumentList,

        [switch]$DoNotUseCredSsp,

        [switch]$UseLocalCredential,

        [pscredential]$Credential,

        [System.Management.Automation.PSVariable[]]$Variable,

        [System.Management.Automation.FunctionInfo[]]$Function,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Parameter(ParameterSetName = 'ScriptBlockFileContentDependency')]
        [Parameter(ParameterSetName = 'ScriptFileContentDependency')]
        [Parameter(ParameterSetName = 'Script')]
        [Parameter(ParameterSetName = 'ScriptFileNameContentDependency')]
        [int]$Retries,

        [Parameter(ParameterSetName = 'ScriptBlock')]
        [Parameter(ParameterSetName = 'ScriptBlockFileContentDependency')]
        [Parameter(ParameterSetName = 'ScriptFileContentDependency')]
        [Parameter(ParameterSetName = 'Script')]
        [Parameter(ParameterSetName = 'ScriptFileNameContentDependency')]
        [int]$RetryIntervalInSeconds,

        [int]$ThrottleLimit = 32,

        [switch]$AsJob,

        [switch]$PassThru,

        [switch]$NoDisplay,

        [switch]$IgnoreAzureLabSources
    )

    Write-LogFunctionEntry
    $customRoleCount = 0

    if ($PSCmdlet.ParameterSetName -in 'Script', 'ScriptBlock', 'ScriptFileContentDependency', 'ScriptBlockFileContentDependency','ScriptFileNameContentDependency')
    {
        if (-not $Retries) { $Retries = Get-LabConfigurationItem -Name InvokeLabCommandRetries }
        if (-not $RetryIntervalInSeconds) { $RetryIntervalInSeconds = Get-LabConfigurationItem -Name InvokeLabCommandRetryIntervalInSeconds }
    }

    if ($AsJob)
    {
        Write-ScreenInfo -Message "Executing lab command activity: '$ActivityName' on machines '$($ComputerName -join ', ')'" -TaskStart

        Write-ScreenInfo -Message 'Activity started in background' -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message "Executing lab command activity: '$ActivityName' on machines '$($ComputerName -join ', ')'" -TaskStart

        Write-ScreenInfo -Message 'Waiting for completion'
    }

    Write-PSFMessage -Message "Executing lab command activity '$ActivityName' on machines '$($ComputerName -join ', ')'"

    #required to suppress verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if (-not (Get-LabVM -IncludeLinux))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    if ($FilePath)
    {
        $isLabPathIsOnLabAzureLabSourcesStorage = if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure')
        {
            Test-LabPathIsOnLabAzureLabSourcesStorage -Path $FilePath
        }
        if ($isLabPathIsOnLabAzureLabSourcesStorage)
        {
            Write-PSFMessage "$FilePath is on Azure. Skipping test."
        }
        elseif (-not (Test-Path -Path $FilePath))
        {
            Write-LogFunctionExitWithError -Message "$FilePath is not on Azure and does not exist"
            return
        }
    }

    if ($PostInstallationActivity)
    {
        $machines = Get-LabVM -ComputerName $ComputerName | Where-Object { $_.PostInstallationActivity -and -not $_.SkipDeployment }
        if (-not $machines)
        {
            Write-PSFMessage 'There are no machine with PostInstallationActivity defined, exiting...'
            return
        }
    }
    else
    {
        $machines = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }

    if (-not $machines)
    {
        Write-ScreenInfo "Cannot invoke the command '$ActivityName', as the specified machines ($($ComputerName -join ', ')) could not be found in the lab." -Type Warning
        return
    }

    if ('Stopped' -in (Get-LabVMStatus -ComputerName $machines -AsHashTable).Values)
    {
        Start-LabVM -ComputerName $machines -Wait
    }

    if ($PostInstallationActivity)
    {
        Write-ScreenInfo -Message 'Performing post-installations tasks defined for each machine' -TaskStart -OverrideNoDisplay

        $results = @()

        foreach ($machine in $machines)
        {
            foreach ($item in $machine.PostInstallationActivity)
            {
                if ($item.RoleName -notin $CustomRoleName -and $CustomRoleName.Count -gt 0)
                {
                    Write-PSFMessage "Skipping installing custom role $($item.RoleName) as it is not part of the parameter `$CustomRoleName"
                    continue
                }

                if ($item.IsCustomRole)
                {
                    Write-ScreenInfo "Installing Custom Role '$(Split-Path -Path $item.DependencyFolder -Leaf)' on machine '$machine'" -TaskStart -OverrideNoDisplay
                    $customRoleCount++
                    #if there is a HostStart.ps1 script for the role
                    $hostStartPath = Join-Path -Path $item.DependencyFolder -ChildPath 'HostStart.ps1'
                    if (Test-Path -Path $hostStartPath)
                    {
                        if (-not $script:data) {$script:data = Get-Lab}
                        $hostStartScript = Get-Command -Name $hostStartPath
                        $hostStartParam = Sync-Parameter -Command $hostStartScript -Parameters $item.Properties -ConvertValue
                        if ($hostStartScript.Parameters.ContainsKey('ComputerName'))
                        {
                            $hostStartParam['ComputerName'] = $machine.Name
                        }
                        $results += & $hostStartPath @hostStartParam
                    }
                }

                $ComputerName = $machine.Name

                $param = @{}
                $param.Add('ComputerName', $ComputerName)

                Write-PSFMessage "Creating session to computers) '$ComputerName'"
                $session = New-LabPSSession -ComputerName $ComputerName -DoNotUseCredSsp:$item.DoNotUseCredSsp -IgnoreAzureLabSources:$IgnoreAzureLabSources.IsPresent
                if (-not $session)
                {
                    Write-LogFunctionExitWithError "Could not create a session to machine '$ComputerName'"
                    return
                }
                $param.Add('Session', $session)

                if ($item.DependencyFolder.Value) { $param.Add('DependencyFolderPath', $item.DependencyFolder.Value) }
                if ($item.ScriptFileName) { $param.Add('ScriptFileName',$item.ScriptFileName) }
                if ($item.ScriptFilePath) { $param.Add('ScriptFilePath', $item.ScriptFilePath) }
                if ($item.KeepFolder) { $param.Add('KeepFolder', $item.KeepFolder) }
                if ($item.ActivityName) { $param.Add('ActivityName', $item.ActivityName) }
                if ($Retries) { $param.Add('Retries', $Retries) }
                if ($RetryIntervalInSeconds) { $param.Add('RetryIntervalInSeconds', $RetryIntervalInSeconds) }
                $param.AsJob      = $true
                $param.PassThru   = $PassThru
                $param.Verbose    = $VerbosePreference
                if ($PSBoundParameters.ContainsKey('ThrottleLimit'))
                {
                    $param.Add('ThrottleLimit', $ThrottleLimit)
                }

                $scriptFullName = Join-Path -Path $param.DependencyFolderPath -ChildPath $param.ScriptFileName
                if ($item.Properties.Count -and (Test-Path -Path $scriptFullName))
                {
                    $script = Get-Command -Name $scriptFullName
                    $temp = Sync-Parameter -Command $script -Parameters $item.Properties

                    Add-VariableToPSSession -Session $session -PSVariable (Get-Variable -Name temp)
                    $param.ParameterVariableName = 'temp'
                }

                if ($item.IsCustomRole)
                {
                    if (Test-Path -Path $scriptFullName)
                    {
                        $param.PassThru = $true
                        $results += Invoke-LWCommand @param
                    }
                }
                else
                {
                    $results += Invoke-LWCommand @param
                }

                if ($item.IsCustomRole)
                {
                    Wait-LWLabJob -Job ($results | Where-Object { $_ -is [System.Management.Automation.Job]} )-ProgressIndicator 15 -NoDisplay

                    #if there is a HostEnd.ps1 script for the role
                    $hostEndPath = Join-Path -Path $item.DependencyFolder -ChildPath 'HostEnd.ps1'
                    if (Test-Path -Path $hostEndPath)
                    {
                        $hostEndScript = Get-Command -Name $hostEndPath
                        $hostEndParam = Sync-Parameter -Command $hostEndScript -Parameters $item.Properties
                        if ($hostEndScript.Parameters.ContainsKey('ComputerName'))
                        {
                            $hostEndParam['ComputerName'] = $machine.Name
                        }
                        $results += & $hostEndPath @hostEndParam
                    }
                }
            }
        }

        if ($customRoleCount)
        {
            $jobs = $results | Where-Object { $_ -is [System.Management.Automation.Job] -and $_.State -eq 'Running' }
            if ($jobs)
            {
                Write-ScreenInfo -Message "Waiting on $($results.Count) custom role installations to finish..." -NoNewLine -OverrideNoDisplay
                Wait-LWLabJob -Job $jobs -Timeout 60 -NoDisplay
            }
            else
            {
                Write-ScreenInfo -Message "$($customRoleCount) custom role installation finished." -OverrideNoDisplay
            }
        }

        Write-ScreenInfo -Message 'Post-installations done' -TaskEnd -OverrideNoDisplay
    }
    else
    {
        $param = @{}
        $param.Add('ComputerName', $machines)

        Write-PSFMessage "Creating session to computer(s) '$machines'"
        $session = @(New-LabPSSession -ComputerName $machines -DoNotUseCredSsp:$DoNotUseCredSsp -UseLocalCredential:$UseLocalCredential -Credential $credential -IgnoreAzureLabSources:$IgnoreAzureLabSources.IsPresent)
        if (-not $session)
        {
            Write-LogFunctionExitWithError "Could not create a session to machine '$machines'"
            return
        }

        if ($Function)
        {
            Write-PSFMessage "Adding functions '$($Function -join ',')' to session"
            $Function | Add-FunctionToPSSession -Session $session
        }

        if ($Variable)
        {
            Write-PSFMessage "Adding variables '$($Variable -join ',')' to session"
            $Variable | Add-VariableToPSSession -Session $session
        }

        $param.Add('Session', $session)

        if ($FilePath)
        {
            $scriptContent = if ($isLabPathIsOnLabAzureLabSourcesStorage)
            {
                #if the script is on an Azure file storage, the host machine cannot access it. The read operation is done on the first Azure machine.
                Invoke-LabCommand -ComputerName ($machines | Where-Object HostType -eq 'Azure')[0] -ScriptBlock { Get-Content -Path $FilePath -Raw } -Variable (Get-Variable -Name FilePath) -NoDisplay -PassThru
            }
            else
            {
                Get-Content -Path $FilePath -Raw
            }
            $ScriptBlock = [scriptblock]::Create($scriptContent)
        }

        if ($ScriptBlock)            { $param.Add('ScriptBlock', $ScriptBlock) }
        if ($Retries)                { $param.Add('Retries', $Retries) }
        if ($RetryIntervalInSeconds) { $param.Add('RetryIntervalInSeconds', $RetryIntervalInSeconds) }
        if ($FileName)               { $param.Add('ScriptFileName', $FileName) }
        if ($ActivityName)           { $param.Add('ActivityName', $ActivityName) }
        if ($ArgumentList)           { $param.Add('ArgumentList', $ArgumentList) }
        if ($DependencyFolderPath)   { $param.Add('DependencyFolderPath', $DependencyFolderPath) }

        $param.PassThru   = $PassThru
        $param.AsJob      = $AsJob
        $param.Verbose    = $VerbosePreference
        if ($PSBoundParameters.ContainsKey('ThrottleLimit'))
        {
            $param.Add('ThrottleLimit', $ThrottleLimit)
        }

        $results = Invoke-LWCommand @param
    }

    if ($AsJob)
    {
        Write-ScreenInfo -Message 'Activity started in background' -TaskEnd
    }
    else
    {
        Write-ScreenInfo -Message 'Activity done' -TaskEnd
    }

    if ($PassThru) { $results }

    Write-LogFunctionExit
}
#endregion Invoke-LabCommand

#region New-LabCimSession
function New-LabCimSession
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory, ParameterSetName = 'ByName', Position = 0)]
        [string[]]
        $ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByMachine')]
        [AutomatedLab.Machine[]]
        $Machine,

        #this is used to recreate a broken session
        [Parameter(Mandatory, ParameterSetName = 'BySession')]
        [Microsoft.Management.Infrastructure.CimSession]
        $Session,

        [switch]
        $UseLocalCredential,

        [switch]
        $DoNotUseCredSsp,

        [pscredential]
        $Credential,

        [int]
        $Retries = 2,

        [int]
        $Interval = 5,

        [switch]
        $UseSSL
    )

    begin
    {
        Write-LogFunctionEntry
        $sessions = @()
        $lab = Get-Lab

        #Due to a problem in Windows 10 not being able to reach VMs from the host
        $testPortTimeout = (Get-LabConfigurationItem -Name Timeout_TestPortInSeconds) * 1000
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            $Machine = Get-LabVM -ComputerName $ComputerName -IncludeLinux

            if (-not $Machine)
            {
                Write-Error "There is no computer with the name '$ComputerName' in the lab"
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'BySession')
        {
            $internalSession = $Session
            $Machine = Get-LabVM -ComputerName $internalSession.LabMachineName -IncludeLinux
        }

        foreach ($m in $Machine)
        {
            $machineRetries = $Retries

            if ($Credential)
            {
                $cred = $Credential
            }
            elseif ($UseLocalCredential -and ($m.IsDomainJoined -and -not $m.HasDomainJoined))
            {
                $cred = $m.GetLocalCredential($true)
            }
            elseif ($UseLocalCredential)
            {
                $cred = $m.GetLocalCredential()
            }
            else
            {
                $cred = $m.GetCredential($lab)
            }

            $param = @{}
            $param.Add('Name', "$($m)_$([guid]::NewGuid())")
            $param.Add('Credential', $cred)

            if ($DoNotUseCredSsp)
            {
                $param.Add('Authentication', 'Default')
            }
            else
            {
                $param.Add('Authentication', 'Credssp')
            }

            if ($m.HostType -eq 'Azure')
            {
                $param.Add('ComputerName', $m.AzureConnectionInfo.DnsName)
                Write-PSFMessage "Azure DNS name for machine '$m' is '$($m.AzureConnectionInfo.DnsName)'"
                $param.Add('Port', $m.AzureConnectionInfo.Port)
                if ($UseSSL)
                {
                    $param.Add('SessionOption', (New-CimSessionOption -SkipCACheck -SkipCNCheck -UseSsl))
                }
            }
            elseif ($m.HostType -eq 'HyperV' -or $m.HostType -eq 'VMWare')
            {
                $doNotUseGetHostEntry = Get-LabConfigurationItem -Name DoNotUseGetHostEntryInNewLabPSSession
                if (-not $doNotUseGetHostEntry)
                {
                    $name = (Get-HostEntry -Hostname $m).IpAddress.IpAddressToString
                }
                elseif (-not [string]::IsNullOrEmpty($m.FriendlyName) -or (Get-LabConfigurationItem -Name SkipHostFileModification))
                {
                    $name = $m.IpV4Address
                }

                if ($name)
                {
                    Write-PSFMessage "Connecting to machine '$m' using the IP address '$name'"
                    $param.Add('ComputerName', $name)
                }
                else
                {
                    Write-PSFMessage "Connecting to machine '$m' using the DNS name '$m'"
                    $param.Add('ComputerName', $m)
                }
                $param.Add('Port', 5985)
            }

            if ($m.OperatingSystemType -eq 'Linux')
            {
                Set-Item -Path WSMan:\localhost\Client\Auth\Basic -Value $true -Force
                $param['SessionOption'] = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck -UseSsl
                $param['Port'] = 5986
                $param['Authentication'] = 'Basic'
            }

            if ($IsLinux -or $IsMacOs)
            {
                $param['Authentication'] = 'Negotiate'
            }

            Write-PSFMessage ("Creating a new CIM Session to machine '{0}:{1}' (UserName='{2}', Password='{3}', DoNotUseCredSsp='{4}')" -f $param.ComputerName, $param.Port, $cred.UserName, $cred.GetNetworkCredential().Password, $DoNotUseCredSsp)

            #session reuse. If there is a session to the machine available, return it, otherwise create a new session
            $internalSession = Get-CimSession | Where-Object {
                $_.ComputerName -eq $param.ComputerName -and
                $_.TestConnection() -and
                $_.Name -like "$($m)_*"
            }

            if ($internalSession)
            {
                if ($internalSession.Runspace.ConnectionInfo.AuthenticationMechanism -eq 'CredSsp' -and (Get-LabVM -ComputerName $internalSession.LabMachineName).HostType -eq 'Azure')
                {
                    #remove the existing session if connecting to Azure LabSource did not work in case the session connects to an Azure VM.
                    Write-ScreenInfo "Removing session to '$($internalSession.LabMachineName)' as ALLabSourcesMapped was false" -Type Warning
                    Remove-LabCimSession -ComputerName $internalSession.LabMachineName
                    $internalSession = $null
                }

                if ($internalSession.Count -eq 1)
                {
                    Write-PSFMessage "Session $($internalSession.Name) is available and will be reused"
                    $sessions += $internalSession
                }
                elseif ($internalSession.Count -ne 0)
                {
                    $sessionsToRemove = $internalSession | Select-Object -Skip (Get-LabConfigurationItem -Name MaxPSSessionsPerVM)
                    Write-PSFMessage "Found orphaned sessions. Removing $($sessionsToRemove.Count) sessions: $($sessionsToRemove.Name -join ', ')"
                    $sessionsToRemove | Remove-CimSession

                    Write-PSFMessage "Session $($internalSession[0].Name) is available and will be reused"
                    #Replaced Select-Object with array indexing because of https://github.com/PowerShell/PowerShell/issues/9185
                    $sessions += ($internalSession | Where-Object State -eq 'Opened')[0] #| Select-Object -First 1
                }
            }

            while (-not $internalSession -and $machineRetries -gt 0)
            {
                Write-PSFMessage "Testing port $($param.Port) on computer '$($param.ComputerName)'"
                $portTest = Test-Port -ComputerName $param.ComputerName -Port $param.Port -TCP -TcpTimeout $testPortTimeout
                if ($portTest.Open)
                {
                    Write-PSFMessage 'Port was open, trying to create the session'
                    $internalSession = New-CimSession @param -ErrorAction SilentlyContinue -ErrorVariable sessionError
                    $internalSession | Add-Member -Name LabMachineName -MemberType ScriptProperty -Value { $this.Name.Substring(0, $this.Name.IndexOf('_')) }

                    if ($internalSession)
                    {
                        Write-PSFMessage "Session to computer '$($param.ComputerName)' created"
                        $sessions += $internalSession
                    }
                    else
                    {
                        Write-PSFMessage -Message "Session to computer '$($param.ComputerName)' could not be created, waiting $Interval seconds ($machineRetries retries). The error was: '$($sessionError[0].FullyQualifiedErrorId)'"
                        if ($Retries -gt 1) { Start-Sleep -Seconds $Interval }
                        $machineRetries--
                    }
                }
                else
                {
                    Write-PSFMessage 'Port was NOT open, cannot create session.'
                    Start-Sleep -Seconds $Interval
                    $machineRetries--
                }
            }

            if (-not $internalSession)
            {
                if ($sessionError.Count -gt 0)
                {
                    Write-Error -ErrorRecord $sessionError[0]
                }
                elseif ($machineRetries -lt 1)
                {
                    if (-not $portTest.Open)
                    {
                        Write-Error -Message "Could not create a session to machine '$m' as the port is closed after $Retries retries."
                    }
                    else
                    {
                        Write-Error -Message "Could not create a session to machine '$m' after $Retries retries."
                    }
                }
            }
        }
    }

    end
    {
        Write-LogFunctionExit -ReturnValue "Session IDs: $(($sessions.ID -join ', '))"
        $sessions
    }
}
#endregion

#region Get-LabCimSession
function Get-LabCimSession
{
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimSession])]
    param 
    (
        [string[]]
        $ComputerName,

        [switch]
        $DoNotUseCredSsp
    )

    $pattern = '\w+_[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}'

    if ($ComputerName)
    {
        $computers = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }
    else
    {
        $computers = Get-LabVM -IncludeLinux
    }

    if (-not $computers)
    {
        Write-Error 'The machines could not be found' -TargetObject $ComputerName
    }

    foreach ($computer in $computers)
    {
        $session = Get-CimSession | Where-Object { $_.Name -match $pattern -and $_.Name -like "$($computer.Name)_*" }

        if (-not $session -and $ComputerName)
        {
            Write-Error "No session found for computer '$computer'" -TargetObject $computer
        }
        else
        {
            $session
        }
    }
}
#endregion

#region Remove-LabCimSession
function Remove-LabCimSession
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]
        $ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByMachine')]
        [AutomatedLab.Machine[]]
        $Machine,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All
    )

    Write-LogFunctionEntry

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $Machine = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }
    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $Machine = Get-LabVM -All -IncludeLinux
    }

    $sessions = foreach ($m in $Machine)
    {
        $param = @{}
        if ($m.HostType -eq 'Azure')
        {
            $param.Add('ComputerName', $m.AzureConnectionInfo.DnsName)
            $param.Add('Port', $m.AzureConnectionInfo.Port)
        }
        elseif ($m.HostType -eq 'HyperV' -or $m.HostType -eq 'VMWare')
        {
            if (Get-LabConfigurationItem -Name DoNotUseGetHostEntryInNewLabPSSession)
            {
                $param.Add('ComputerName', $m.Name)
            }
            elseif (Get-LabConfigurationItem -Name SkipHostFileModification)
            {
                $param.Add('ComputerName', $m.IpV4Address)
            }
            else
            {
                $param.Add('ComputerName', (Get-HostEntry -Hostname $m).IpAddress.IpAddressToString)
            }
            $param.Add('Port', 5985)
        }

        Get-CimSession | Where-Object {
            $_.ComputerName -eq $param.ComputerName -and
        $_.Name -like "$($m)_*" }
    }

    $sessions | Remove-CimSession -ErrorAction SilentlyContinue

    Write-PSFMessage "Removed $($sessions.Count) PSSessions..."
    Write-LogFunctionExit
}
#endregion

#region Install-LabRdsCertificate
function Install-LabRdsCertificate
{
    [CmdletBinding()]
    param ( )

    $lab = Get-Lab
    if (-not $lab)
    {
        return
    }

    $machines = Get-LabVM -All | Where-Object -FilterScript { $_.OperatingSystemType -eq 'Windows' -and $_.OperatingSystem.Version -ge 6.3 -and -not $_.SkipDeployment }
    if (-not $machines)
    {
        return
    }

    $jobs = foreach ($machine in $machines)
    {
        Invoke-LabCommand -ComputerName $machine -ActivityName 'Exporting RDS certs' -NoDisplay -ScriptBlock {
            [string[]]$SANs = $machine.FQDN
            $cmdlet = Get-Command -Name New-SelfSignedCertificate -ErrorAction SilentlyContinue
            if ($machine.HostType -eq 'Azure' -and $cmdlet)
            {
                $SANs += $machine.AzureConnectionInfo.DnsName
            }

            $cert = if ($cmdlet.Parameters.ContainsKey('Subject'))
            {
                New-SelfSignedCertificate -Subject "CN=$($machine.Name)" -DnsName $SANs -CertStoreLocation 'Cert:\LocalMachine\My' -Type SSLServerAuthentication
            }
            else
            {
                New-SelfSignedCertificate -DnsName $SANs -CertStoreLocation 'Cert:\LocalMachine\my'
            }
            $rdsSettings = Get-CimInstance -ClassName Win32_TSGeneralSetting -Namespace ROOT\CIMV2\TerminalServices
            $rdsSettings.SSLCertificateSHA1Hash = $cert.Thumbprint
            $rdsSettings | Set-CimInstance
            $null = $cert | Export-Certificate -FilePath "C:\$($machine.Name).cer" -Type CERT -Force
        } -Variable (Get-Variable machine) -AsJob -PassThru
    }

    Wait-LWLabJob -Job $jobs -NoDisplay
    $tmp = Join-Path -Path $lab.LabPath -ChildPath Certificates
    if (-not (Test-Path -Path $tmp)) { $null = New-Item -ItemType Directory -Path $tmp }
    foreach ($session in (New-LabPSSession -ComputerName $machines))
    {
        $fPath = Join-Path -Path $tmp -ChildPath "$($session.LabMachineName).cer"
        Receive-File -SourceFilePath "C:\$($session.LabMachineName).cer" -DestinationFilePath $fPath -Session $session
        $null = Import-Certificate -FilePath $fPath -CertStoreLocation 'Cert:\LocalMachine\Root'
    }
}
#endregion

#region Uninstall-LabRdsCertificate
function Uninstall-LabRdsCertificate
{
    [CmdletBinding()]
    param ( )

    $lab = Get-Lab
    if (-not $lab)
    {
        return
    }

    foreach ($certFile in (Get-ChildItem -File -Path (Join-Path -Path $lab.LabPath -ChildPath Certificates) -Filter *.cer -ErrorAction SilentlyContinue))
    {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
        $cert.Import($certFile.FullName)
        if ($cert.Thumbprint)
        {
            Get-Item -Path ('Cert:\LocalMachine\Root\{0}' -f $cert.Thumbprint) | Remove-Item
        }

        $certFile | Remove-Item
    }
}
#endregion
