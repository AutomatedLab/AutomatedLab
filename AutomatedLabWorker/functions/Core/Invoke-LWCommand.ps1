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
        $result = if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $DependencyFolderPath) )
        { 
            Test-LabPathIsOnLabAzureLabSourcesStorage -Path $DependencyFolderPath
        }
        else
        {
            Test-Path -Path $DependencyFolderPath
        }
        
        if (-not $result)
        {
            Write-Error "The DependencyFolderPath '$DependencyFolderPath' could not be found"
            return
        }
    }

    if ($ScriptFilePath)
    {
        $result = if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $ScriptFilePath))
        {
            Test-LabPathIsOnLabAzureLabSourcesStorage -Path $ScriptFilePath
        }
        else
        {
            Test-Path -Path $ScriptFilePath
        }
        
        if (-not $result)
        {
            Write-Error "The ScriptFilePath '$ScriptFilePath' could not be found"
            return
        }
    }

    $internalSession = New-Object System.Collections.ArrayList
    $internalSession.AddRange(
        @($Session | Foreach-Object {
                if ($_.State -eq 'Broken')
                {
                    New-LabPSSession -Session $_ -ErrorAction SilentlyContinue
                }
                else
                {
                    $_
                }
        } | Where-Object {$_}) # Remove empty values. Invoke-LWCommand fails too early if AsJob is present and a broken session cannot be recreated
    )

    if (-not $ActivityName)
    {
        $ActivityName = '<unnamed>'
    }
    Write-PSFMessage -Message "Starting Activity '$ActivityName'"

    #if the image path is set we mount the image to the VM
    if ($PSCmdlet.ParameterSetName -like 'FileContentDependency*')
    {
        Write-PSFMessage -Message "Copying files from '$DependencyFolderPath' to $ComputerName..."

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $DependencyFolderPath))
        {
            Invoke-Command -Session $Session -ScriptBlock { Copy-Item -Path $args[0] -Destination / -Recurse -Force } -ArgumentList $DependencyFolderPath
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
                    Send-Directory -SourceFolderPath $DependencyFolderPath -DestinationFolder (Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath (Split-Path -Path $DependencyFolderPath -Leaf)) -Session $internalSession
                }
                else
                {
                    Send-File -SourceFilePath $DependencyFolderPath -DestinationFolderPath (Get-LabConfigurationItem -Name OsRoot) -Session $internalSession
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'FileContentDependencyRemoteScript')
        {
            $cmd = ''
            if ($ScriptFileName)
            {
                $cmd += "& '$(Join-Path -Path / -ChildPath (Split-Path $DependencyFolderPath -Leaf))\$ScriptFileName'"
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

            Write-PSFMessage -Message "Invoking script '$ScriptFileName'"

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
        $job = Invoke-Command @parameters -ErrorAction SilentlyContinue
    }
    else
    {
        while ($Retries -gt 0 -and $internalSession.Count -gt 0)
        {
            $nonAvailableSessions = @($internalSession | Where-Object State -ne Opened)
            foreach ($nonAvailableSession in $nonAvailableSessions)
            {
                Write-PSFMessage "Re-creating unavailable session for machine '$($nonAvailableSessions.ComputerName)'"
                $internalSession.Add((New-LabPSSession -Session $nonAvailableSession)) | Out-Null
                Write-PSFMessage "removing unavailable session for machine '$($nonAvailableSessions.ComputerName)'"
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
                Write-PSFMessage "Scriptblock did not run on all machines, retrying (Retries = $Retries)"
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
        Write-PSFMessage "The Output of the task on machine '$($ComputerName)' will be available in the variable '$($resultVariable.Name)'"
    }

    Write-PSFMessage -Message "Finished Installation Activity '$ActivityName'"

    Write-LogFunctionExit -ReturnValue $resultVariable
}
