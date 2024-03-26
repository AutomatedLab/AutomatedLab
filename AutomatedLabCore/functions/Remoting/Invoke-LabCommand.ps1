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
        [switch]$PreInstallationActivity,

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

    $parameterSetsWithRetries = 'Script',
        'ScriptBlock',
        'ScriptFileContentDependency',
        'ScriptBlockFileContentDependency',
        'ScriptFileNameContentDependency',
        'PostInstallationActivity',
        'PreInstallationActivity'

    if ($PSCmdlet.ParameterSetName -in $parameterSetsWithRetries)
    {
        if (-not $Retries)
        {
            $Retries = Get-LabConfigurationItem -Name InvokeLabCommandRetries
        }
        if (-not $RetryIntervalInSeconds)
        {
            $RetryIntervalInSeconds = Get-LabConfigurationItem -Name InvokeLabCommandRetryIntervalInSeconds
        }
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

    if ($PreInstallationActivity)
    {
        $machines = Get-LabVM -ComputerName $ComputerName | Where-Object { $_.PreInstallationActivity -and -not $_.SkipDeployment }
        if (-not $machines)
        {
            Write-PSFMessage 'There are no machine with PreInstallationActivity defined, exiting...'
            return
        }
    }
    elseif ($PostInstallationActivity)
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

    if ($PostInstallationActivity -or $PreInstallationActivity)
    {
        Write-ScreenInfo -Message 'Performing pre/post-installation tasks defined for each machine' -TaskStart -OverrideNoDisplay

        $results = @()

        foreach ($machine in $machines)
        {
            $activities = if ($PreInstallationActivity) { $machine.PreInstallationActivity } elseif ($PostInstallationActivity) { $machine.PostInstallationActivity }
            foreach ($item in $activities)
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
                        $hostStartParam = Sync-Parameter -Command $hostStartScript -Parameters ($item.SerializedProperties | ConvertFrom-PSFClixml -ErrorAction SilentlyContinue) -ConvertValue
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

                foreach ($serVariable in ($item.SerializedVariables | ConvertFrom-PSFClixml -ErrorAction SilentlyContinue))
                {
                    $existingVariable = Get-Variable -Name $serVariable.Name -ErrorAction SilentlyContinue
                    if ($existingVariable.Value -ne $serVariable.Value)
                    {
                        Set-Variable -Name $serVariable.Name -Value $serVariable.Value -Force
                    }

                    Add-VariableToPSSession -Session $session -PSVariable (Get-Variable -Name $serVariable.Name)
                }

                foreach ($serFunction in ($item.SerializedFunctions | ConvertFrom-PSFClixml -ErrorAction SilentlyContinue))
                {
                    $existingFunction = Get-Command -Name $serFunction.Name -ErrorAction SilentlyContinue
                    if ($existingFunction.ScriptBlock -eq $serFunction.ScriptBlock)
                    {
                        Set-Item -Path "function:\$($serFunction.Name)" -Value $serFunction.ScriptBlock -Force
                    }

                    Add-FunctionToPSSession -Session $session -FunctionInfo (Get-Command -Name $serFunction.Name)
                }

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
                if ($item.SerializedProperties -and (Test-Path -Path $scriptFullName))
                {
                    $script = Get-Command -Name $scriptFullName
                    $temp = Sync-Parameter -Command $script -Parameters ($item.SerializedProperties | ConvertFrom-PSFClixml -ErrorAction SilentlyContinue)

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
                        $hostEndParam = Sync-Parameter -Command $hostEndScript -Parameters ($item.SerializedProperties | ConvertFrom-PSFClixml -ErrorAction SilentlyContinue)
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

        Write-ScreenInfo -Message 'Pre/Post-installations done' -TaskEnd -OverrideNoDisplay
    }
    else
    {
        $param = @{}
        $param.Add('ComputerName', $machines)

        Write-PSFMessage "Creating session to computer(s) '$machines'"
        $session = @(New-LabPSSession -ComputerName $machines -DoNotUseCredSsp:$DoNotUseCredSsp -UseLocalCredential:$UseLocalCredential -Credential $credential -IgnoreAzureLabSources:$IgnoreAzureLabSources.IsPresent)
        if (-not $session)
        {
            Write-ScreenInfo -Type Error -Message "Could not create a session to machine '$machines'"
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

    if ($PassThru)
    {
        $results
    }

    Write-LogFunctionExit
}
