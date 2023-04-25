function Wait-LabVM
{
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName,

        [double]$TimeoutInMinutes = (Get-LabConfigurationItem -Name Timeout_WaitLabMachine_Online),

        [int]$PostDelaySeconds = 0,

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = (Get-LabConfigurationItem -Name DefaultProgressIndicator),

        [switch]$DoNotUseCredSsp,

        [switch]$NoNewLine
    )

    begin
    {
        if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator

        Write-LogFunctionEntry

        $lab = Get-Lab
        if (-not $lab)
        {
            Write-Error 'No definitions imported, so there is nothing to do. Please use Import-Lab first'
            return
        }

        $vms = [System.Collections.Generic.List[AutomatedLab.Machine]]::new()
    }

    process
    {
        $null = Get-LabVM -ComputerName $ComputerName -IncludeLinux | Foreach-Object {$vms.Add($_) }

        if (-not $vms)
        {
            Write-Error 'None of the given machines could be found'
            return
        }
    }

    end
    {
        if ((Get-Command -ErrorAction SilentlyContinue -Name New-PSSession).Parameters.Values.Name -contains 'HostName' )
        {
            # Quicker than reading in the file on unsupported configurations
            $sshHosts = (Get-LabSshKnownHost -ErrorAction SilentlyContinue).ComputerName
        }
        $jobs = foreach ($vm in $vms)
        {
            $session = $null
            #remove the existing sessions to ensure a new one is created and the existing one not reused.
            if ((Get-Command -ErrorAction SilentlyContinue -Name New-PSSession).Parameters.Values.Name -contains 'HostName' -and $sshHosts -and $vm.Name -notin $sshHosts)
            {
                Install-LabSshKnownHost
                $sshHosts = (Get-LabSshKnownHost -ErrorAction SilentlyContinue).ComputerName
            }
            Remove-LabPSSession -ComputerName $vm

            if (-not ($IsLinux -or $IsMacOs)) { netsh.exe interface ip delete arpcache | Out-Null }

            #if called without using DoNotUseCredSsp and the machine is not yet configured for CredSsp, call Wait-LabVM again but with DoNotUseCredSsp. Wait-LabVM enables CredSsp if called with DoNotUseCredSsp switch.
            if (-not $vm.SkipDeployment -and $lab.DefaultVirtualizationEngine -eq 'HyperV')
            {
                $machineMetadata = Get-LWHypervVMDescription -ComputerName $vm.ResourceName
                if (($machineMetadata.InitState -band [AutomatedLab.LabVMInitState]::EnabledCredSsp) -ne [AutomatedLab.LabVMInitState]::EnabledCredSsp -and -not $DoNotUseCredSsp)
                {
                    Wait-LabVM -ComputerName $vm -TimeoutInMinutes $TimeoutInMinutes -PostDelaySeconds $PostDelaySeconds -ProgressIndicator $ProgressIndicator -DoNotUseCredSsp -NoNewLine:$NoNewLine
                }
            }

            $session = New-LabPSSession -ComputerName $vm -UseLocalCredential -Retries 1 -DoNotUseCredSsp:$DoNotUseCredSsp -ErrorAction SilentlyContinue

            if ($session)
            {
                Write-PSFMessage "Computer '$vm' was reachable"
                Start-Job -Name "Waiting for machine '$vm'" -ScriptBlock {
                    param (
                        [string]$ComputerName
                    )

                    $ComputerName
                } -ArgumentList $vm.Name
            }
            else
            {
                Write-PSFMessage "Computer '$($vm.ComputerName)' was not reachable, waiting..."
                Start-Job -Name "Waiting for machine '$vm'" -ScriptBlock {
                    param(
                        [Parameter(Mandatory)]
                        [byte[]]$LabBytes,

                        [Parameter(Mandatory)]
                        [string]$ComputerName,

                        [Parameter(Mandatory)]
                        [bool]$DoNotUseCredSsp
                    )

                    $VerbosePreference = $using:VerbosePreference

                    Import-Module -Name Az* -ErrorAction SilentlyContinue
                    Import-Module -Name AutomatedLab.Common -ErrorAction Stop
                    Write-Verbose "Importing Lab from $($LabBytes.Count) bytes"
                    Import-Lab -LabBytes $LabBytes -NoValidation -NoDisplay

                    #do 5000 retries. This job is cancelled anyway if the timeout is reached
                    Write-Verbose "Trying to create session to '$ComputerName'"
                    $session = New-LabPSSession -ComputerName $ComputerName -UseLocalCredential  -Retries 5000 -DoNotUseCredSsp:$DoNotUseCredSsp

                    return $ComputerName
                } -ArgumentList $lab.Export(), $vm.Name, $DoNotUseCredSsp
            }
        }

        Write-PSFMessage "Waiting for $($jobs.Count) machines to respond in timeout ($TimeoutInMinutes minute(s))"

        Wait-LWLabJob -Job $jobs -ProgressIndicator $ProgressIndicator -NoNewLine:$NoNewLine -NoDisplay -Timeout $TimeoutInMinutes

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
            Write-PSFMessage "The following machines are ready: $($completed -join ', ')"

            foreach ($machine in (Get-LabVM -ComputerName $completed))
            {
                if ($machine.SkipDeployment -or $machine.HostType -ne 'HyperV') { continue }
                $machineMetadata = Get-LWHypervVMDescription -ComputerName $machine.ResourceName
                if ($machineMetadata.InitState -eq [AutomatedLab.LabVMInitState]::Uninitialized)
                {
                    $machineMetadata.InitState = [AutomatedLab.LabVMInitState]::ReachedByAutomatedLab
                    Set-LWHypervVMDescription -Hashtable $machineMetadata -ComputerName $machine.ResourceName
                    Enable-LabAutoLogon -ComputerName $ComputerName
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

                    Set-LWHypervVMDescription -Hashtable $machineMetadata -ComputerName $(Get-LabVM -ComputerName $machine).ResourceName
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
}
