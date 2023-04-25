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

        $jitTs = Get-LabConfigurationItem -Name AzureJitTimestamp
        if ((Get-LabConfigurationItem -Name AzureEnableJit) -and $lab.DefaultVirtualizationEngine -eq 'Azure' -and (-not $jitTs -or ((Get-Date) -ge $jitTs)) )
        {
            # Either JIT has not been requested, or current date exceeds timestamp
            Request-LabAzureJitAccess
        }
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
                try
                {
                    $azConInfResolved = [System.Net.Dns]::GetHostByName($m.AzureConnectionInfo.DnsName)
                }
                catch
                {

                }

                if (-not $m.AzureConnectionInfo.DnsName -or -not $azConInfResolved)
                {
                    $m.AzureConnectionInfo = Get-LWAzureVMConnectionInfo -ComputerName $m
                }

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
                elseif ($doNotUseGetHostEntry -or -not [string]::IsNullOrEmpty($m.FriendlyName) -or (Get-LabConfigurationItem -Name SkipHostFileModification))
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
                if ($internalSession.Runspace.ConnectionInfo.AuthenticationMechanism -eq 'CredSsp' -and (Get-LabVM -ComputerName $internalSession.LabMachineName).HostType -eq 'Azure' -and -not $lab.AzureSettings.IsAzureStack)
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
