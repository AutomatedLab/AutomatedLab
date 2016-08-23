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
        [ValidateScript({
                    [System.IO.Directory]::Exists($_) -or [System.IO.File]::Exists($_)
                }
        )]
        [string]$DependencyFolderPath,
        
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'NoDependencyLocalScript')]
        [ValidateScript({
                    [System.IO.File]::Exists($_)
                }
        )]
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
        [int]$Retries,

        [Parameter(ParameterSetName = 'IsoImageDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'FileContentDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'NoDependencyScriptBlock')]
        [int]$RetryIntervalInSeconds,
        
        [switch]$AsJob,
        
        [switch]$PassThru
    )
    
    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    Write-LogFunctionEntry

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
        
        if ($PSCmdlet.ParameterSetName -eq 'FileContentDependencyRemoteScript')
        {
            $cmd = @"
                $(if ($ScriptFileName) { "&'$(Join-Path -Path C:\ -ChildPath (Split-Path $DependencyFolderPath -Leaf))\$ScriptFileName'" })
                $(if (-not $KeepFolder) { "Remove-Item '$(Join-Path -Path C:\ -ChildPath (Split-Path $DependencyFolderPath -Leaf))' -Recurse -Force" } )
"@
            
            Write-Verbose -Message "Invoking script '$ScriptFileName'"
            
            $parameters = @{ }
            $parameters.Add('Session', $internalSession)
            $parameters.Add('ScriptBlock', [scriptblock]::Create($cmd))
            $parameters.Add('ArgumentList', $arguments)
            if ($AsJob)
            {
                $parameters.Add('AsJob', $AsJob)
                $parameters.Add('JobName', $ActivityName)
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
    }
    
    $parameters.Add('Verbose', $Verbose)
    $parameters.Add('Debug', $Debug)

    $result = New-Object System.Collections.ArrayList

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

            $result.AddRange([System.Collections.ArrayList]@(Invoke-Command @parameters -ErrorAction SilentlyContinue -ErrorVariable invokeError))

            #remove all sessions for machines successfully invoked the command
            foreach ($machineFinished in ($result | Where-Object { $_ -like 'LABHOSTNAME*' }))
            {
                $machineFinishedName = $machineFinished.Substring($machineFinished.IndexOf(':') + 1)
                $internalSession.Remove(($internalSession | Where-Object LabMachineName -eq $machineFinishedName))
            }
            $result = $result | Where-Object { $_ -notlike 'LABHOSTNAME*' }

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
    
    if ($invokeError.Count -and -not $AsJob)
    {
        foreach ($error in $invokeError)
        {
            Write-Error -ErrorRecord $error
        }
    }
    
    Write-Verbose -Message "Finished Installation Activity '$ActivityName'"
    
    Write-LogFunctionExit -ReturnValue $resultVariable
}
#endregion Invoke-LWCommand

#region Install-LWSoftwarePackage
function Install-LWSoftwarePackage
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        
        [string]$CommandLine,
        
        [int]$Timeout = 10,
        
        [ValidateNotNullOrEmpty()]
        [string]$ProcessName,
        
        [ValidateNotNullOrEmpty()]
        [string]$ProcessDescription        
    )
    
    if (-not $ProcessName)
    {
        $ProcessName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    }
    $cmd = $Path + ' ' + $CommandLine
    
    #--------------------------------------------------------------------------------------
    
    $start = Get-Date
    Write-Verbose -Message "Starting setup of '$ProcessName' with the following command"
    Write-Verbose -Message "`t$cmd"
    Write-Verbose -Message "The timeout is $Timeout minutes, starting at '$start'"
    
    $installationMethod = [System.IO.Path]::GetExtension($Path)
    $installationFile = [System.IO.Path]::GetFileName($Path)
    
    if ($installationMethod -eq '.exe')
    {
        Write-Verbose -Message 'Starting installation of Exe file'
        
        $args = @{ }
        $args.Add('FilePath', $Path)
        if ($CommandLine)
        {
            $args.Add('ArgumentList', $CommandLine)
        }
        $args.Add('PassThru', $true)
        
        $p = Start-Process @args
        Write-Verbose -Message "The installation process ID is $($p.Id)"
        
        $queryExpression = "`$_.Name -eq '$ProcessName'"
        if ($ProcessDescription)
        {
            $queryExpression += "-and `$_.Description -eq '$processDescription'"
        }
        $queryExpression = [scriptblock]::Create($queryExpression)
        
        Write-Verbose -Message 'Query expression for looking for the setup process:'
        Write-Verbose -Message "`t$queryExpression"
        
        if (-not (Get-Process | Where-Object -FilterScript $queryExpression))
        {
            Write-Error -Message "Installation of '$ProcessName' did not start"
            return
        }
        else
        {
            $p = Get-Process | Where-Object -FilterScript $queryExpression
            Write-Verbose -Message "Installation process is '$($p.Name)' with ID $($p.Id)"
        }
        
        while (Get-Process | Where-Object -FilterScript $queryExpression)
        {
            if ((Get-Date).AddMinutes(-$Timeout) -gt $start)
            {
                Write-Error -Message "Installation of '$ProcessName' hit the timeout of $Timeout minutes. Killing the setup process"
                
                if ($ProcessDescription)
                {
                    Get-Process |
                    Where-Object -FilterScript {
                        $_.Name -eq $ProcessName -and $_.Description -eq $ProcessDescription
                    } |
                    Stop-Process -Force
                }
                else
                {
                    Get-Process -Name $ProcessName | Stop-Process -Force
                }
                
                Write-Error -Message "Installation of '$installationFile' was not successfull"
                return
            }
            
            Start-Sleep -Seconds 5
        }
    }
    elseif ($installationMethod -eq '.msi')
    {
        Write-Verbose -Message 'Starting installation of MSI file'
        
        if (-not $CommandLine)
        {
            $CommandLine =
            @(
                "/I `"$Path`"", # Install this MSI
                '/QN', # Quietly, without a UI
                "/L*V `"$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetFileNameWithoutExtension($Path)).log`""     # Verbose output to this log
            )
        }
        else
        {
            $CommandLine += ' ' + "/I `"$Path`"" # Install this MSI
        }
        
        Write-Verbose -Message 'Installation arguments for MSI are:'
        Write-Verbose -Message "`tPath: $Path"
        Write-Verbose -Message "`tLog File: '`t$([System.IO.Path]::GetTempPath())$([System.IO.Path]::GetFileNameWithoutExtension($Path)).log'"
        
        $p = Start-Process -FilePath 'msiexec' -ArgumentList $CommandLine -PassThru
        Write-Verbose "The installation process ID is $($p.Id)"
        $p.WaitForExit()
    }
    elseif ($installationMethod -eq '.msu')
    {
        Write-Verbose -Message 'Starting installation of MSU file'
        
        $tempRemoteFolder = [System.IO.Path]::GetTempFileName()
        Remove-Item -Path $tempRemoteFolder
        mkdir -Path $tempRemoteFolder
        expand.exe -F:* $Path $tempRemoteFolder
        
        $cabFile = (Get-ChildItem -Path $tempRemoteFolder\*.cab -Exclude WSUSSCAN.cab).FullName
        
        $pinfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = 'dism.exe'
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.Arguments = "/Online /Add-Package /PackagePath:""$cabFile"" /NoRestart /Quiet"
        
        $p = New-Object -TypeName System.Diagnostics.Process
        $p.StartInfo = $pinfo
        Write-Verbose -Message "Starting process $($pinfo.FileName) $($pinfo.Arguments)"
        $null = $p.Start()
        Write-Verbose "The installation process ID is $($p.Id)"
        $p.WaitForExit()
        Write-Verbose -Message 'Process exited. Reading output'
        $p.StandardOutput.ReadToEnd()
        $p.StandardError.ReadToEnd()
        Write-Verbose -Message 'Reading output done'
        
        Write-Verbose -Message 'Cleaning up source and temp files'
        
        Remove-Item -Path $tempRemoteFolder -Recurse -Confirm:$false
        Remove-Item -Path $Path -Confirm:$false
        Write-Verbose -Message 'Cleaning up source and temp files done'
    }
    else
    {
        Write-Error -Message 'The extension of the file to install is unknown'
        return
    }
    
    Write-Verbose "Exit code of installation process is '$($p.ExitCode)'"
    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010 -and $p.ExitCode -ne $null)
    {
        Write-Error -Message "Installation process returned error code: $($p.ExitCode). See the log file for more information"
    }
    else
    {
        Write-Verbose -Message "Installation of '$installationFile' finished successfully"
    }
    
    Write-Verbose -Message 'Exiting'
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
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -Source ""`$(@(Get-WmiObject -Class Win32_CDRomDrive)[-1].Drive)\sources\sxs"" -All:`$$IncludeAllSubFeature")
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
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -Source ""`$(@(Get-WmiObject -Class Win32_CDRomDrive)[-1].Drive)\sources\sxs"" -All:`$$IncludeAllSubFeature")
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
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature")
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
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature")
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
        [switch]$ReturnResults
    )
    
    Write-LogFunctionEntry
    
    if ($ProgressIndicator) { Write-ProgressIndicator }

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
                if ($ProgressIndicator) { Write-ProgressIndicator }
                $ProgressIndicatorTimer = (Get-Date)
            }
        }
        until (($jobs.State -notcontains 'Running' -and $jobs.State -notcontains 'AtBreakPoint') -or ((Get-Date) -gt ($Start.AddMinutes($Timeout))))
    }
    
    if (-not $NoNewLine -and $ProgressIndicator) { Write-ProgressIndicatorEnd }
    
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

        if ($ReturnResults)
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