function Get-LabInstallationActivity
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [string]$DependencyFolder,

        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [string]$IsoImage,

        [Parameter(ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(ParameterSetName = 'FileContentDependencyLocalScript')]
        [Parameter(ParameterSetName = 'CustomRole')]
        [switch]$KeepFolder,

        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyRemoteScript')]
        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyRemoteScript')]
        [string]$ScriptFileName,

        [Parameter(Mandatory, ParameterSetName = 'IsoImageDependencyLocalScript')]
        [Parameter(Mandatory, ParameterSetName = 'FileContentDependencyLocalScript')]
        [string]$ScriptFilePath,

        [Parameter(ParameterSetName = 'CustomRole')]
        [hashtable]$Properties,

        [System.Management.Automation.PSVariable[]]$Variable,
    
        [System.Management.Automation.FunctionInfo[]]$Function,

        [switch]$DoNotUseCredSsp,

        [string]$CustomRole
    )

    begin
    {
        Write-LogFunctionEntry
        $activity = New-Object -TypeName AutomatedLab.InstallationActivity
        if ($Variable) { $activity.SerializedVariables = $Variable | ConvertTo-PSFClixml}
        if ($Function) { $activity.SerializedFunctions = $Function | ConvertTo-PSFClixml}
        if (-not $Properties)
        {
            $Properties = @{ } 
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -like 'FileContentDependency*')
        {
            $activity.DependencyFolder = $DependencyFolder
            $activity.KeepFolder = $KeepFolder.ToBool()
            if ($ScriptFilePath)
            {
                $activity.ScriptFilePath = $ScriptFilePath
            }
            else
            {
                $activity.ScriptFileName = $ScriptFileName
            }
        }
        elseif ($PSCmdlet.ParameterSetName -like 'IsoImage*')
        {
            $activity.IsoImage = $IsoImage
            if ($ScriptFilePath)
            {
                $activity.ScriptFilePath = $ScriptFilePath
            }
            else
            {
                $activity.ScriptFileName = $ScriptFileName
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'CustomRole')
        {
            $activity.DependencyFolder = Join-Path -Path (Join-Path -Path (Get-LabSourcesLocation -Local) -ChildPath 'CustomRoles') -ChildPath $CustomRole
            $activity.KeepFolder = $KeepFolder.ToBool()
            $activity.ScriptFileName = "$CustomRole.ps1"
            $activity.IsCustomRole = $true

            #The next sections compares the given custom role properties with with the custom role parameters.
            #Custom role parameters are taken form the main role script as well as the HostStart.ps1 and the HostEnd.ps1
            $scripts = $activity.ScriptFileName, 'HostStart.ps1', 'HostEnd.ps1'
            $unknownParameters = New-Object System.Collections.Generic.List[string]

            foreach ($script in $scripts)
            {
                $scriptFullName = Join-Path -Path $activity.DependencyFolder -ChildPath $script
                if (-not (Test-Path -Path $scriptFullName))
                {
                    continue
                }
                $scriptInfo = Get-Command -Name $scriptFullName
                $commonParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
                $parameters = $scriptInfo.Parameters.GetEnumerator() | Where-Object Key -NotIn $commonParameters

                #If the custom role knows about a ComputerName parameter and if there is no value defined by the user, add add empty value now.
                #Later that will be filled with the computer name of the computer the role is assigned to when the HostStart and the HostEnd scripts are invoked.
                if ($Properties)
                {
                    if (($parameters | Where-Object Key -eq 'ComputerName') -and -not $Properties.ContainsKey('ComputerName'))
                    {
                        $Properties.Add('ComputerName', '')
                    }
                }

                #test if all mandatory parameters are defined
                foreach ($parameter in $parameters)
                {
                    if ($parameter.Value.Attributes.Mandatory -and -not $properties.ContainsKey($parameter.Key))
                    {
                        Write-Error "There is no value defined for mandatory property '$($parameter.Key)' and custom role '$CustomRole'" -ErrorAction Stop
                    }
                }

                #test if there are custom role properties defined that do not map to the custom role parameters
                if ($Properties)
                {
                    foreach ($property in $properties.GetEnumerator())
                    {
                        if (-not $scriptInfo.Parameters.ContainsKey($property.Key) -and -not $unknownParameters.Contains($property.Key))
                        {
                            $unknownParameters.Add($property.Key)
                        }
                    }
                }
            }

            #antoher loop is required to remove all unknown parameters that are added due to the order of the first loop
            foreach ($script in $scripts)
            {
                $scriptFullName = Join-Path -Path $activity.DependencyFolder -ChildPath $script
                if (-not (Test-Path -Path $scriptFullName))
                {
                    continue
                }
                $scriptInfo = Get-Command -Name $scriptFullName
                $commonParameters = [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
                $parameters = $scriptInfo.Parameters.GetEnumerator() | Where-Object Key -NotIn $commonParameters

                if ($Properties)
                {
                    foreach ($property in $properties.GetEnumerator())
                    {
                        if ($scriptInfo.Parameters.ContainsKey($property.Key) -and $unknownParameters.Contains($property.Key))
                        {
                            $unknownParameters.Remove($property.Key) | Out-Null
                        }
                    }
                }
            }

            if ($unknownParameters.Count -gt 0)
            {
                Write-Error "The defined properties '$($unknownParameters -join ', ')' are unknown for custom role '$CustomRole'" -ErrorAction Stop
            }

            if ($Properties)
            {
                $activity.SerializedProperties = $Properties | ConvertTo-PSFClixml -ErrorAction SilentlyContinue
            }
        }

        $activity.DoNotUseCredSsp = $DoNotUseCredSsp
    }

    end
    {
        Write-LogFunctionExit -ReturnValue $activity
        return $activity
    }
}
