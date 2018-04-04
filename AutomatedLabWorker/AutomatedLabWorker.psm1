﻿#region Invoke-LWCommand
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
        
        [string]$ParameterVariableName,

        [Parameter(ParameterSetName = 'IsoImageDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'FileContentDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'NoDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'NoDependencyLocalScript')]        
        [int]$Retries,

        [Parameter(ParameterSetName = 'IsoImageDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'FileContentDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'NoDependencyScriptBlock')]
        [Parameter(ParameterSetName = 'FileContentDependencyRemoteScript')]
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
                    Send-Directory -SourceFolderPath $DependencyFolderPath -DestinationFolder (Join-Path -Path C:\ -ChildPath (Split-Path -Path $DependencyFolderPath -Leaf)) -Session $internalSession
                }
                else
                {
                    Send-File -SourceFilePath $DependencyFolderPath -DestinationFolderPath C:\ -Session $internalSession
                }
            }
        }
        
        if ($PSCmdlet.ParameterSetName -eq 'FileContentDependencyRemoteScript')
        {
            $cmd = ''
            if ($ScriptFileName) 
            {
                $cmd +=  "& '$(Join-Path -Path C:\ -ChildPath (Split-Path $DependencyFolderPath -Leaf))\$ScriptFileName'"
            }
            if ($ParameterVariableName)
            {
                $cmd += " @$ParameterVariableName"
            }
            $cmd += "`n"
            if (-not $KeepFolder) 
            {
                $cmd += "Remove-Item '$(Join-Path -Path C:\ -ChildPath (Split-Path $DependencyFolderPath -Leaf))' -Recurse -Force" 
            }
            
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
        $parameters.ScriptBlock = [scriptblock]::Create($parameters.ScriptBlock.ToString() + "`n;`"LABHOSTNAME:`$([System.Net.Dns]::GetHostName())`"`n")
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

        [switch]$IncludeManagementTools,
        
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
                $cmd = [scriptblock]::Create("Install-WindowsFeature $($FeatureName -join ', ') -Source ""`$(@(Get-WmiObject -Class Win32_CDRomDrive)[-1].Drive)\sources\sxs"" -IncludeAllSubFeature:`$$IncludeAllSubFeature -IncludeManagementTools:`$$IncludeManagementTools")
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
                $cmd = [scriptblock]::Create("`$null;Import-Module -Name ServerManager; Add-WindowsFeature $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature -IncludeManagementTools:`$$IncludeManagementTools")
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
        
        [switch]$IncludeManagementTools,
        
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
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -All -NoRestart")
            }
            else
            {
                $cmd = [scriptblock]::Create("Install-WindowsFeature $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature -IncludeManagementTools:`$$IncludeManagementTools")
            }
        }
        else
        {
            if ($m.OperatingSystem.Installation -eq 'Client')
            {
                $cmd = [scriptblock]::Create("Enable-WindowsOptionalFeature -Online -FeatureName $($FeatureName -join ', ') -All -NoRestart")
            }
            else
            {
                $cmd = [scriptblock]::Create("Import-Module -Name ServerManager; Add-WindowsFeature $($FeatureName -join ', ') -IncludeAllSubFeature:`$$IncludeAllSubFeature -IncludeManagementTools:`$$IncludeManagementTools")
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

        [ValidateRange(0, 300)]
        [int]$ProgressIndicator = $PSCmdlet.MyInvocation.MyCommand.Module.PrivateData.DefaultProgressIndicator,

        [int]$Timeout = 60,

        [switch]$NoNewLine,

        [switch]$NoDisplay,

        [switch]$PassThru
    )

    if (-not $PSBoundParameters.ContainsKey('ProgressIndicator')) { $PSBoundParameters.Add('ProgressIndicator', $ProgressIndicator) } #enables progress indicator
    
    Write-LogFunctionEntry
    
    Write-ProgressIndicator

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

    Write-ScreenInfo -Message "Waiting for job(s) to complete with ID(s): $($Job.Id -join ', ')" -TaskStart

    if ($jobs -and ($jobs.State -contains 'Running' -or $jobs.State -contains 'AtBreakpoint'))
    {
        $jobs = Get-Job -Id $jobs.ID
        $ProgressIndicatorTimer = (Get-Date)
        do
        {
            Start-Sleep -Seconds 1
            if (((Get-Date) - $ProgressIndicatorTimer).TotalSeconds -ge $ProgressIndicator)
            {
                Write-ProgressIndicator
                $ProgressIndicatorTimer = (Get-Date)
            }
        }
        until (($jobs.State -notcontains 'Running' -and $jobs.State -notcontains 'AtBreakPoint') -or ((Get-Date) -gt ($Start.AddMinutes($Timeout))))
    }
    
    Write-ProgressIndicatorEnd
    
    if ((Get-Date) -gt ($Start.AddMinutes($Timeout)))
    {
        $jobs = Get-Job -Id $jobs.Id | Where-Object State -eq Running
        Write-Error -Message "Timeout while waiting for job $($jobs.ID -join ', ')"
    }
    else
    {
        Write-ScreenInfo -Message 'Job(s) no longer running' -TaskEnd

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