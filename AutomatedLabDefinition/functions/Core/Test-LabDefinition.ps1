function Test-LabDefinition
{
    [CmdletBinding()]
    param (
        [string]$Path,

        [switch]$Quiet
    )

    Write-LogFunctionEntry

    $lab = Get-LabDefinition
    if (-not $lab)
    {
        $lab = Get-Lab -ErrorAction SilentlyContinue
    }

    if (-not $lab -and -not $Path)
    {
        Write-Error 'There is no lab loaded and no path specified. Please either import a lab using Import-Lab or point to a lab.xml document using the path parameter'
        return $false
    }

    if (-not $Path)
    {
        $Path = Join-Path -Path $lab.LabPath -ChildPath (Get-LabConfigurationItem LabFileName)
    }

    $labDefinition = Import-LabDefinition -Path $Path -PassThru
    $skipHostFileModification = Get-LabConfigurationItem -Name SkipHostFileModification

    foreach ($machine in (Get-LabMachineDefinition | Where-Object HostType -in 'HyperV', 'VMware' ))
    {
        $hostEntry = Get-HostEntry -HostName $machine

        if ($machine.FriendlyName -or $skipHostFileModification)
        {
                continue #if FriendlyName / ResourceName is defined, host file will not be modified
        }

        if ($hostEntry -and $hostEntry.IpAddress.IPAddressToString -ne $machine.IpV4Address)
        {
            Write-ScreenInfo "There is already an entry for machine '$($machine.Name)' in the hosts file pointing to other IP address(es) ($((Get-HostEntry -HostName $machine).IpAddress.IPAddressToString -join ',')) than the machine '$($machine.Name)' in this lab will have ($($machine.IpV4Address)). Cannot continue."
            $wrongIpInHostEntry = $true
        }
    }
    if ($wrongIpInHostEntry) { return $false }

    #we need to get the machine config files as well
    $machineDefinitionFiles = $labDefinition.MachineDefinitionFiles.Path

    Write-PSFMessage "There are $($machineDefinitionFiles.Count) machine XML file referenced in the lab xml file"
    foreach ($machineDefinitionFile in $machineDefinitionFiles)
    {
        if (-not (Test-Path -Path $machineDefinitionFile))
        {
            throw 'Error importing the machines. Verify the paths in the section <MachineDefinitionFiles> of the lab definition XML file.'
        }
    }

    $Script:ValidationPass = $true

    Write-PSFMessage 'Starting validation against all xml files'
    try
    {
        [AutomatedLab.XmlValidatorArgs]::XmlPath = $Path

        $summaryMessageContainer = New-Object AutomatedLab.ValidationMessageContainer

        $assembly = [System.Reflection.Assembly]::GetAssembly([AutomatedLab.ValidatorBase])

        $validatorCount = 0
        foreach ($t in $assembly.GetTypes())
        {
            if ($t.IsSubclassOf([AutomatedLab.ValidatorBase]))
            {
                try
                {
                    $validator = [AutomatedLab.ValidatorBase][System.Activator]::CreateInstance($t)
                    Write-Debug "Validator '$($validator.MessageContainer.ValidatorName)' took $($validator.Runtime.TotalMilliseconds) milliseconds"

                    $summaryMessageContainer += $validator.MessageContainer
                    $validatorCount++
                }
                catch
                {
                    Write-ScreenInfo "Could not invoke validator $t" -Type Warning
                }
            }
        }

        $summaryMessageContainer.AddSummary()
    }
    catch
    {
        throw $_
    }

    Write-PSFMessage -Message "Lab Validation complete, overvall runtime was $($summaryMessageContainer.Runtime)"

    $messages = $summaryMessageContainer | ForEach-Object { $_.GetFilteredMessages('All') }
    if (-not $Quiet)
    {
        Write-ScreenInfo ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Default } | Out-String)

        if ($VerbosePreference -eq 'Continue')
        {
            Write-PSFMessage ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::VerboseDebug } | Out-String)
        }
    }
    else
    {
        if ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Warning })
        {
            $messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Warning } | ForEach-Object `
            {
                Write-ScreenInfo -Message "Issue: '$($_.TargetObject)'. Cause: $($_.Message)" -Type Warning
            }
        }

        if ($messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Error })
        {
            $messages | Where-Object { $_.Type -band [AutomatedLab.MessageType]::Error } | ForEach-Object `
            {
                Write-ScreenInfo -Message "Issue: '$($_.TargetObject)'. Cause: $($_.Message)" -Type Error
            }
        }
    }

    if ($messages | Where-Object Type -eq ([AutomatedLab.MessageType]::Error))
    {
        $Script:ValidationPass = $false
        $false
    }
    else
    {
        $Script:ValidationPass = $true
        $true
    }

    Write-LogFunctionExit
}
