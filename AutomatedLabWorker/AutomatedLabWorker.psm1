#region Invoke-LWCommand
function Invoke-LWCommand
{
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
        
        [string]$ActivityName,
        
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyScriptBlock')]
        [string]$DependencyFolderPath,
        
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'NoDependencyLocalScript')]
        [string]$ScriptFilePath,
        
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyRemoteScript')]
        [string]$ScriptFileName,
        
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyScriptBlock')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyScriptBlock')]
        [Parameter(Mandatory, ParameterSetName = 'NoDependencyScriptBlock')]
        [scriptblock]$ScriptBlock,
        
        [Parameter(ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(ParameterSetName = 'FileContentDependencyScriptBlock')]
        [switch]$KeepFolder,
        
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyScriptBlock')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyScript')]
        [string]$IsoImagePath,
        
        [object[]]$ArgumentList,

        [Parameter(ParameterSetName = 'IsoImageDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'FileContentDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'NoDependencyScriptBlock')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'NoDependencyLocalScript')]        
        [int]$Retries,

        [Parameter(ParameterSetName = 'IsoImageDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'FileContentDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'NoDependencyScriptBlock')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'NoDependencyLocalScript')]        
        [int]$RetryIntervalInSeconds,
        
        [int]$ThrottleLimit = 32,
        
        [switch]$AsJob,
        
        [switch]$PassThru
    )
    
    Write-LogFunctionEntry
    
    #required to supress verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if ($DependencyFolderPath)
    {
        if (-not (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $DependencyFolderPath) -and -not (Test-Path -Path $DependencyFolderPath))
        {
            Write-Error "The DependencyFolderPath '$DependencyFolderPath' could not be found"
            return
        }
    }
    
    if ($ScriptFilePath)
    {
        if (-not (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $ScriptFilePath) -and -not (Test-Path -Path $ScriptFilePath -PathType Leaf))
        {
            Write-Error "The ScriptFilePath '$ScriptFilePath' could not be found"
            return
        }
    }

    $internalSession = New-Object System.Collections.ArrayList
    $internalSession.AddRange($Session)
    
    if (-not $ActivityName)
    {
        $ActivityName = '<unnamed>'
    }
    Write-Verbose -Message "Starting Activity '$ActivityName'"
    
    #if the image path is set we mount the image to the VM
    if ($PSCmdlet.ParameterSetName -like 'FileContentDependency*')
    {
        Write-Verbose -Message "Copying files from '$DependencyFolderPath' to $ComputerName..."
        
        if (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $DependencyFolderPath)
        {
            Invoke-Command -Session $Session -ScriptBlock { Copy-Item -Path $args[0] -Destination C:\ -Recurse -Force } -ArgumentList $DependencyFolderPath
        }
        else
        {
            try
            {
                Copy-LabFileItem -Path $DependencyFolderPath -ComputerName $ComputerName -ErrorAction Stop
            }
            catch
            {
                if ((Get-Item -Path $DependencyFolderPath).PSIsContainer)
                {
                    Send-Directory -Source $DependencyFolderPath -Destination (Join-Path -Path C:\ -ChildPath (Split-Path -Path $DependencyFolderPath -Leaf)) -Session $internalSession
                }
                else
                {
                    Send-File -Source $DependencyFolderPath -Destination (Join-Path -Path C:\ -ChildPath (Split-Path -Path $DependencyFolderPath -Leaf)) -Session $internalSession
                }
            }
        }
        
        if ($PSCmdlet.ParameterSetName -eq 'FileContentDependencyRemoteScript')
        {
            $cmd = @"
                $(if ($ScriptFileName) { "&' $(Join-Path -Path C:\ -ChildPath (Split-Path $DependencyFolderPath -Leaf))\$ScriptFileName'" })
                $(if (-not $KeepFolder) { "Remove-Item '$(Join-Path -Path C:\ -ChildPath (Split-Path $DependencyFolderPath -Leaf))' -Recurse -Force" } )
"@
            
            Write-Verbose -Message "Invoking script '$ScriptFileName'"
            
            $parameters = @{ }
            $parameters.Add('Session', $internalSession)
            $parameters.Add('ScriptBlock', [scriptblock]::Create($cmd))
            $parameters.Add('ArgumentList', $ArgumentList)
            if ($AsJob)
            {
                $parameters.Add('AsJob', $AsJob)
                $parameters.Add('JobName', $ActivityName)
            }
            if ($PSBoundParameters.ContainsKey('ThrottleLimit'))
            {
                $parameters.Add('ThrottleLimit', $ThrottleLimit)
            }
        }
        else
        {
            $parameters = @{ }
            $parameters.Add('Session', $internalSession)
            if ($ScriptFilePath)
            {
                $parameters.Add('FilePath', (Join-Path -Path $DependencyFolderPath -ChildPath $ScriptFilePath))
            }
            if ($ScriptBlock)
            {
                $parameters.Add('ScriptBlock', $ScriptBlock)
            }
            $parameters.Add('ArgumentList', $ArgumentList)
            if ($AsJob)
            {
                $parameters.Add('AsJob', $AsJob)
                $parameters.Add('JobName', $ActivityName)
            }
            if ($PSBoundParameters.ContainsKey('ThrottleLimit'))
            {
                $parameters.Add('ThrottleLimit', $ThrottleLimit)
            }
        }
    }
    elseif ($PSCmdlet.ParameterSetName -like 'NoDependency*')
    {
        $parameters = @{ }
        $parameters.Add('Session', $internalSession)
        if ($ScriptFilePath)
        {
            $parameters.Add('FilePath', $ScriptFilePath)
        }
        if ($ScriptBlock)
        {
            $parameters.Add('ScriptBlock', $ScriptBlock)
        }
        $parameters.Add('ArgumentList', $ArgumentList)
        if ($AsJob)
        {
            $parameters.Add('AsJob', $AsJob)
            $parameters.Add('JobName', $ActivityName)
        }
        if ($PSBoundParameters.ContainsKey('ThrottleLimit'))
        {
            $parameters.Add('ThrottleLimit', $ThrottleLimit)
        }
    }
    
    if ($VerbosePreference -eq 'Continue') { $parameters.Add('Verbose', $VerbosePreference) }
    if ($DebugPreference -eq 'Continue') { $parameters.Add('Debug', $DebugPreference) }

    [System.Collections.ArrayList]$result = New-Object System.Collections.ArrayList

    if (-not $AsJob -and $parameters.ScriptBlock)
    {
        Write-Debug 'Adding LABHOSTNAME to scriptblock' 
        #in some situations a retry makes sense. In order to know which machines have done the job, the scriptblock must return the hostname
        $parameters.ScriptBlock = [scriptblock]::Create($parameters.ScriptBlock.ToString() + "`n;`"LABHOSTNAME:`$(HOSTNAME.EXE)`"`n")
    }

    if ($AsJob)
    {
        $job = Invoke-Command @parameters -ErrorAction SilentlyContinue -ErrorVariable invokeError
    }
    else
    {
        while ($Retries -gt 0 -and $internalSession.Count -gt 0)
        {
            $nonAvailableSessions = @($internalSession | Where-Object State -ne Opened)
            foreach ($nonAvailableSession in $nonAvailableSessions)
            {
                Write-Verbose "Re-creating unavailable session for machine '$($nonAvailableSessions.ComputerName)'"
                $internalSession.Add((New-LabPSSession -Session $nonAvailableSession)) | Out-Null
                Write-Verbose "removing unavailable session for machine '$($nonAvailableSessions.ComputerName)'"
                $internalSession.Remove($nonAvailableSession)
            }

            $result.AddRange(@(Invoke-Command @parameters))

            #remove all sessions for machines successfully invoked the command
            foreach ($machineFinished in ($result | Where-Object { $_ -like 'LABHOSTNAME*' }))
            {
                $machineFinishedName = $machineFinished.Substring($machineFinished.IndexOf(':') + 1)
                $internalSession.Remove(($internalSession | Where-Object LabMachineName -eq $machineFinishedName))
            }
            $result = @($result | Where-Object { $_ -notlike 'LABHOSTNAME*' })

            $Retries--

            if ($Retries -gt 0 -and $internalSession.Count -gt 0)
            {
                Write-Verbose "Scriptblock did not run on all machines, retrying (Retries = $Retries)"
                Start-Sleep -Seconds $RetryIntervalInSeconds
            }
        }
    }

    if ($PassThru)
    {
        if ($AsJob)
        {
            $job
        }
        else
        {
            $result
        }
    }
    else
    {
        $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
        $resultVariable.Value = $result
        Write-Verbose "The Output of the task on machine '$($ComputerName)' will be available in the variable '$($resultVariable.Name)'"
    }
    
    Write-Verbose -Message "Finished Installation Activity '$ActivityName'"
    
    Write-LogFunctionExit -ReturnValue $resultVariable
}
#endregion Invoke-LWCommand

function Install-LWSoftwarePackage
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [string]$CommandLine,
        
        [bool]$AsScheduledJob,
        
        [bool]$UseShellExecute
    )
    
    #region New-InstallProcess
    function New-InstallProcess
    {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,

            [string]$CommandLine,
            
            [bool]$UseShellExecute
        )
    
        $pInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
        $pInfo.FileName = $Path
        
        $pInfo.UseShellExecute = $UseShellExecute
        if (-not $UseShellExecute)
        {
            $pInfo.RedirectStandardError = $true
            $pInfo.RedirectStandardOutput = $true
        }
        $pInfo.Arguments = $CommandLine

        $p = New-Object -TypeName System.Diagnostics.Process
        $p.StartInfo = $pInfo
        Write-Verbose -Message "Starting process: $($pInfo.FileName) $($pInfo.Arguments)"
        $p.Start() | Out-Null
        Write-Verbose "The installation process ID is $($p.Id)"
        $p.WaitForExit()
        Write-Verbose -Message 'Process exited. Reading output'

        $params = @{ Process = $p }
        if (-not $UseShellExecute)
        {
            $params.Add('Output', $p.StandardOutput.ReadToEnd())
            $params.Add('Error', $p.StandardError.ReadToEnd())
        }
        New-Object -TypeName PSObject -Property $params
    }
    #endregion New-InstallProcess

    if (-not (Test-Path -Path $Path -PathType Leaf))
    {
        Write-Error "The file '$Path' could not found"
        return        
    }
        
    $start = Get-Date
    Write-Verbose -Message "Starting setup of '$ProcessName' with the following command"
    Write-Verbose -Message "`t$cmd"
    Write-Verbose -Message "The timeout is $Timeout minutes, starting at '$start'"
    
    $installationMethod = [System.IO.Path]::GetExtension($Path)
    $installationFile = [System.IO.Path]::GetFileName($Path)
    
    if ($installationMethod -eq '.msi')
    {
        Write-Verbose -Message 'Starting installation of MSI file'
        
        [string]$CommandLine = if (-not $CommandLine)
        {
            @(
                "/I `"$Path`"", # Install this MSI
                '/QN', # Quietly, without a UI
                "/L*V `"$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetFileNameWithoutExtension($Path)).log`""     # Verbose output to this log
            )
        }
        else
        {
            '/I {0} {1}' -f $Path, $CommandLine # Install this MSI
        }
        
        Write-Verbose -Message 'Installation arguments for MSI are:'
        Write-Verbose -Message "`tPath: $Path"
        Write-Verbose -Message "`tLog File: '`t$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetFileNameWithoutExtension($Path)).log'"
        
        $Path = 'msiexec.exe'
    }
    elseif ($installationMethod -eq '.msu')
    {
        Write-Verbose -Message 'Starting installation of MSU file'
        
        $tempRemoteFolder = [System.IO.Path]::GetTempFileName()
        Remove-Item -Path $tempRemoteFolder
        mkdir -Path $tempRemoteFolder
        expand.exe -F:* $Path $tempRemoteFolder
        
        $cabFile = (Get-ChildItem -Path $tempRemoteFolder\*.cab -Exclude WSUSSCAN.cab).FullName

        $Path = 'dism.exe'
        $CommandLine = "/Online /Add-Package /PackagePath:""$cabFile"" /NoRestart /Quiet"
    }
    elseif ($installationMethod -eq '.exe')
    { }
    else
    {
        Write-Error -Message 'The extension of the file to install is unknown'
        return
    }

    if ($AsScheduledJob)
    {
        $jobName = "AL_$([guid]::NewGuid())"
        Write-Verbose "In the AsScheduledJob mode, creating scheduled job named '$jobName'"
            
        if ($PSVersionTable.PSVersion -lt '3.0')
        {
            $processName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
            $d = "{0:HH:mm}" -f (Get-Date).AddMinutes(1)
            SCHTASKS /Create /SC ONCE /ST $d /TN $jobName /TR "$Path $CommandLine" /RU "SYSTEM" | Out-Null
            while (-not ($p))
            {
                Start-Sleep -Milliseconds 200
                $p = Get-Process -Name $processName -ErrorAction SilentlyContinue
            }

            $p.WaitForExit()
            Write-Verbose -Message 'Process exited. Reading output'

            $params = @{ Process = $p }
            $params.Add('Output', "Output cannot be retrieved using this AsScheduledJob on PowerShell 2.0")
            $params.Add('Error', "Errors cannot be retrieved using this AsScheduledJob on PowerShell 2.0")
            New-Object -TypeName PSObject -Property $params

            
        }
        else
        {
            $scheduledJob = Register-ScheduledJob -ScriptBlock (Get-Command -Name New-InstallProcess).ScriptBlock -ArgumentList $Path, $CommandLine, $UseShellExecute -Name $jobName -RunNow
            Write-Verbose "ScheduledJob object registered with the ID $($scheduledJob.Id)"
            
            while (-not $job)
            {
                $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
            }        
            $job | Wait-Job | Out-Null
            $result = $job | Receive-Job
        }
    }
    else
    {
        $result = New-InstallProcess -Path $Path -CommandLine $CommandLine -UseShellExecute $UseShellExecute
    }
    
    Start-Sleep -Seconds 5
    
    if ($AsScheduledJob)
    {
        if ($PSVersionTable.PSVersion -lt '3.0')
        {
            schtasks.exe /DELETE /TN $jobName /F | Out-Null
        }
        else
        {
            Write-Verbose "Unregistering scheduled job with ID $($scheduledJob.Id)"
            $scheduledJob | Unregister-ScheduledJob
        }
    }

    if ($installationMethod -eq '.msu')
    {
        Remove-Item -Path $tempRemoteFolder -Recurse -Confirm:$false
    }
        
    Write-Verbose "Exit code of installation process is '$($result.Process.ExitCode)'"
    if ($result.Process.ExitCode -ne 0 -and $result.Process.ExitCode -ne 3010 -and $result.Process.ExitCode -ne $null)
    {
        throw $result.Error
    }
    else
    {
        Write-Verbose -Message "Installation of '$installationFile' finished successfully"
        $result.Output
    }
}
#endregion Install-LWSoftwarePackage

#region Install-LWHypervWindowsFeature
function Install-LWHypervWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [AutomatedLab.Machine[]]$Machine,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,
        
        [switch]$IncludeAllSubFeature,
        
        [switch]$UseLocalCredential,
        
        [switch]$AsJob,
        
        [switch]$PassThru
    )
    
    Write-LogFunctionEntry
    
    $activityName = "Install Windows Feature(s): '$($FeatureName -join ', ')'"
    
    $result = @()
    foreach ($m in $Machine)
    {
        if ($m.OperatingSystem.Version -ge [System.Version]'6.2')
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -Source ""`$(@(Get-WmiObject -Class Win32_CDRomDrive)[-1].Drive)\sources\sxs"" -All:`$$IncludeAllSubFeature -NoRestart")
            }
            else
            {
                $cmd = [scriptblock]::Create("Install-WindowsFeature $($FeatureName -join ', ') -Source ""`$(@(Get-WmiObject -Class Win32_CDRomDrive)[-1].Drive)\sources\sxs"" -IncludeAllSubFeature:`$$IncludeAllSubFeature")
            }
        }
        else
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -Source ""`$(@(Get-WmiObject -Class Win32_CDRomDrive)[-1].Drive)\sources\sxs"" -All:`$$IncludeAllSubFeature -NoRestart")
            }
            else
            {
                $cmd = [scriptblock]::Create("`$null;Import-Module -Name ServerManager; Add-WindowsFeature $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature")
            }
        }
        
        $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -NoDisplay -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
    }

    if ($PassThru)
    {
        $result
    }

    Write-LogFunctionExit
}
#endregion Install-LWHypervWindowsFeature

#region Install-LWAzureWindowsFeature
function Install-LWAzureWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [AutomatedLab.Machine[]]$Machine,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,
        
        [switch]$IncludeAllSubFeature,
        
        [switch]$UseLocalCredential,
        
        [switch]$AsJob,
        
        [switch]$PassThru
    )
    
    Write-LogFunctionEntry
    
    $activityName = "Install Windows Feature(s): '$($FeatureName -join ', ')'"
    
    $result = @()
    foreach ($m in $machine)
    {
        if ($m.OperatingSystem.Version -ge [System.Version]'6.2')
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature -NoRestart")
            }
            else
            {
                $cmd = [scriptblock]::Create("Install-WindowsFeature $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature")
            }
        }
        else
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature -NoRestart")
            }
            else
            {
                $cmd = [scriptblock]::Create("Import-Module -Name ServerManager; Add-WindowsFeature $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature")
            }
        }
        
        $result += Invoke-LabCommand -ComputerName $m -ActivityName $activityName -ScriptBlock $cmd -UseLocalCredential:$UseLocalCredential -AsJob:$AsJob -PassThru:$PassThru
    }
    
    if ($PassThru)
    {
        $result
    }
    
    Write-LogFunctionExit
}
#endregion Install-LWAzureWindowsFeature

#region Wait-LWLabJob
function Wait-LWLabJob
{
    Param
    (
        [Parameter(Mandatory, ParameterSetName = 'ByJob')]
        [AllowNull()]
        [AllowEmptyCollection()] 
        [System.Management.Automation.Job[]]$Job,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$Name,

        [int]$ProgressIndicator,
        [int]$Timeout = 60,
        [switch]$NoNewLine,
        [switch]$NoDisplay,
        [switch]$PassThru
    )
    
    Write-LogFunctionEntry
    
    if ($ProgressIndicator -and -not $NoDisplay) { Write-ProgressIndicator }

    if (-not $Job -and -not $Name)
    {
        Write-Verbose 'There is no job to wait for'
        Write-LogFunctionExit
        return
    }
    
    $start = (Get-Date)

    if ($Job)
    {
        $jobs = Get-Job -Id $Job.ID
    }
    else
    {
        $jobs = Get-Job -Name $Name
    }

    if (-not $NoDisplay) { Write-ScreenInfo -Message "Waiting for job(s) to complete with ID(s): $($Job.Id -join ', ')" -TaskStart }
        
    if ($jobs -and ($jobs.State -contains 'Running' -or $jobs.State -contains 'AtBreakpoint'))
    {
        $jobs = Get-Job -Id $jobs.ID
        $ProgressIndicatorTimer = (Get-Date)
        do
        {
            Start-Sleep -Seconds 1
            if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator)
            {
                if ($ProgressIndicator -and -not $NoDisplay) { Write-ProgressIndicator }
                $ProgressIndicatorTimer = (Get-Date)
            }
        }
        until (($jobs.State -notcontains 'Running' -and $jobs.State -notcontains 'AtBreakPoint') -or ((Get-Date) -gt ($Start.AddMinutes($Timeout))))
    }
    
    if (-not $NoNewLine -and $ProgressIndicator -and -not $NoDisplay) { Write-ProgressIndicatorEnd }
    
    if ((Get-Date) -gt ($Start.AddMinutes($Timeout)))
    {
        $jobs = Get-Job -Id $jobs.Id | Where-Object State -eq Running
        Write-Error -Message "Timeout while waiting for job $($jobs.ID -join ', ')"
    }
    else
    {
        if (-not $NoDisplay)
        {
            Write-ScreenInfo -Message 'Job(s) no longer running' -TaskEnd
        }

        if ($PassThru)
        {
            $jobs | Receive-Job -ErrorAction SilentlyContinue -ErrorVariable jobErrors

            #PSRemotingTransportException are very likely due to restarts or problems AL cannot recover
            $jobErrors = $jobErrors | Where-Object { $_.Exception -isnot [System.Management.Automation.Remoting.PSRemotingTransportException] }

            foreach ($jobError in $jobErrors)
            {
                Write-Error -ErrorRecord $jobError
            }
        }
    }

    Write-LogFunctionExit
}
#endregion Wait-LWLabJob