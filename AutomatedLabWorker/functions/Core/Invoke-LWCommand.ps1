function Invoke-LWCommand {
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [System.Management.Automation.Runspaces.PSSession[]]$Session,

        [string]$ActivityName,

        [string]$DependencyFolderPath,

        [Parameter(Mandatory, ParameterSetName = 'LocalScript')]
        [string]$ScriptFilePath,

        [Parameter(Mandatory, ParameterSetName = 'ScriptBlock')]
        [scriptblock]$ScriptBlock,

        [switch]$KeepFolder,

        [object[]]$ArgumentList,

        [string]$ParameterVariableName,

        [int]$Retries = (Get-LabConfigurationItem -Name InvokeLabCommandRetries),

        [int]$RetryIntervalInSeconds = (Get-LabConfigurationItem -Name InvokeLabCommandRetryIntervalInSeconds),

        [int]$ThrottleLimit = 32,

        [switch]$AsJob,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    #required to supress verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($DependencyFolderPath) {
        $result = if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $DependencyFolderPath) ) { 
            Test-LabPathIsOnLabAzureLabSourcesStorage -Path $DependencyFolderPath
        }
        else {
            Test-Path -Path $DependencyFolderPath
        }
        
        if (-not $result) {
            Write-Error "The DependencyFolderPath '$DependencyFolderPath' could not be found"
            return
        }
    }

    if ($ScriptFilePath) {
        $result = if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $ScriptFilePath)) {
            Test-LabPathIsOnLabAzureLabSourcesStorage -Path $ScriptFilePath
        }
        else {
            Test-Path -Path $ScriptFilePath
        }
        
        if (-not $result) {
            Write-Error "The ScriptFilePath '$ScriptFilePath' could not be found"
            return
        }
    }

    $internalSession = New-Object System.Collections.ArrayList
    $internalSession.AddRange(
        @($Session | Foreach-Object {
                if ($_.State -eq 'Broken') {
                    New-LabPSSession -Session $_ -ErrorAction SilentlyContinue
                }
                else {
                    $_
                }
            } | Where-Object { $_ }) # Remove empty values. Invoke-LWCommand fails too early if AsJob is present and a broken session cannot be recreated
    )

    if (-not $ActivityName) {
        $ActivityName = '<unnamed>'
    }
    Write-PSFMessage -Message "Starting Activity '$ActivityName'"

    #if the image path is set we mount the image to the VM
    if ($DependencyFolderPath) {
        Write-PSFMessage -Message "Copying files from '$DependencyFolderPath' to $ComputerName..."

        if ((Get-Lab).DefaultVirtualizationEngine -eq 'Azure' -and (Test-LabPathIsOnLabAzureLabSourcesStorage -Path $DependencyFolderPath)) {
            Invoke-Command -Session $Session -ScriptBlock { Copy-Item -Path $args[0] -Destination / -Recurse -Force } -ArgumentList $DependencyFolderPath
        }
        else {
            try {
                Copy-LabFileItem -Path $DependencyFolderPath -ComputerName $ComputerName -ErrorAction Stop
            }
            catch {
                if ((Get-Item -Path $DependencyFolderPath).PSIsContainer) {
                    Send-Directory -SourceFolderPath $DependencyFolderPath -DestinationFolder (Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath (Split-Path -Path $DependencyFolderPath -Leaf)) -Session $internalSession
                }
                else {
                    Send-File -SourceFilePath $DependencyFolderPath -DestinationFolderPath (Get-LabConfigurationItem -Name OsRoot) -Session $internalSession
                }
            }
        }
    }

    if ($DependencyFolderPath -and $ScriptFilePath) {
        $remoteDependencyPath = Join-Path -Path (Get-LabConfigurationItem -Name OsRoot) -ChildPath (Split-Path $DependencyFolderPath -Leaf)
        $newScriptFilePath = Join-Path -Path $remoteDependencyPath -ChildPath (Split-Path -Path $ScriptFilePath -Leaf)
        $cmd = "& '$newScriptFilePath'"

        if ($ParameterVariableName) {
            $cmd += " @$ParameterVariableName"
        }
        $cmd += "`n"

        if (-not $KeepFolder -and $DependencyFolderPath) {
            $cmd += "Remove-Item '$remoteDependencyPath' -Recurse -Force"
        }

        Write-PSFMessage -Message "Invoking script '$(Split-Path -Leaf -Path $ScriptFilePath)'"

        $parameters = @{ }
        $parameters.Add('Session', $internalSession)
        $parameters.Add('ScriptBlock', [scriptblock]::Create($cmd))
        $parameters.Add('ArgumentList', $ArgumentList)
        if ($AsJob) {
            $parameters.Add('AsJob', $AsJob)
            $parameters.Add('JobName', $ActivityName)
        }
        if ($PSBoundParameters.ContainsKey('ThrottleLimit')) {
            $parameters.Add('ThrottleLimit', $ThrottleLimit)
        }
    }
    else {
        $parameters = @{ }
        $parameters.Add('Session', $internalSession)
        if ($ScriptFilePath) {
            $parameters.Add('FilePath', $ScriptFilePath)
        }
        if ($ScriptBlock) {
            $parameters.Add('ScriptBlock', $ScriptBlock)
        }
        $parameters.Add('ArgumentList', $ArgumentList)
        if ($AsJob) {
            $parameters.Add('AsJob', $AsJob)
            $parameters.Add('JobName', $ActivityName)
        }
        if ($PSBoundParameters.ContainsKey('ThrottleLimit')) {
            $parameters.Add('ThrottleLimit', $ThrottleLimit)
        }
    }

    if ($VerbosePreference -eq 'Continue') { $parameters.Add('Verbose', $VerbosePreference) }
    if ($DebugPreference -eq 'Continue') { $parameters.Add('Debug', $DebugPreference) }

    [System.Collections.ArrayList]$result = New-Object System.Collections.ArrayList

    if ($AsJob) {
        $job = Invoke-Command @parameters -ErrorAction SilentlyContinue
    }
    else {
        while ($Retries -gt 0 -and $internalSession.Count -gt 0) {
            $nonAvailableSessions = @($internalSession | Where-Object State -ne Opened)
            foreach ($nonAvailableSession in $nonAvailableSessions) {
                Write-PSFMessage "Re-creating unavailable session for machine '$($nonAvailableSessions.ComputerName)'"
                $internalSession.Add((New-LabPSSession -Session $nonAvailableSession)) | Out-Null
                Write-PSFMessage "removing unavailable session for machine '$($nonAvailableSessions.ComputerName)'"
                $internalSession.Remove($nonAvailableSession)
            }

            $results = Invoke-Command @parameters
            $result.AddRange(@($results))

            foreach ($remoteRunspace in $results.RunspaceId | Sort-Object -Unique) {
                $successfulRun = Get-LabPSSession | Where-Object InstanceId -eq $remoteRunspace
                if (-not $successfulRun) { continue }

                Write-PSFMessage "Script ran to completion on machine '$($successfulRun.LabMachineName)'"
                $internalSession.Remove(($internalSession | Where-Object InstanceId -eq $successfulRun.InstanceId))
            }

            $Retries--

            if ($Retries -gt 0 -and $internalSession.Count -gt 0) {
                Write-PSFMessage "Scriptblock did not run on all machines, retrying (Retries = $Retries)"
                Start-Sleep -Seconds $RetryIntervalInSeconds
            }
        }
    }

    if ($PassThru) {
        if ($AsJob) {
            $job
        }
        else {
            $result
        }
    }
    else {
        $resultVariable = New-Variable -Name ("AL_$([guid]::NewGuid().Guid)") -Scope Global -PassThru
        $resultVariable.Value = $result
        Write-PSFMessage "The Output of the task on machine '$($ComputerName)' will be available in the variable '$($resultVariable.Name)'"
    }

    Write-PSFMessage -Message "Finished Installation Activity '$ActivityName'"

    Write-LogFunctionExit -ReturnValue $resultVariable
}
