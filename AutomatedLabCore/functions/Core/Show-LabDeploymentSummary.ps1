function Show-LabDeploymentSummary
{
    [OutputType([System.TimeSpan])]
    [Cmdletbinding()]
    param (
        [switch]$Detailed
    )

    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        Write-ScreenInfo "There is no lab information available in the current PowerShell session. Deploy a lab with AutomatedLab or import an already deployed lab with the 'Import-Lab' cmdlet."
        return
    }

    $lab = Get-Lab
    $ts = New-TimeSpan -Start $Global:AL_DeploymentStart -End (Get-Date)
    $hoursPlural = ''
    $minutesPlural = ''
    $secondsPlural = ''

    if ($ts.Hours   -gt 1) { $hoursPlural   = 's' }
    if ($ts.minutes -gt 1) { $minutesPlural = 's' }
    if ($ts.Seconds -gt 1) { $secondsPlural = 's' }

    $machines = Get-LabVM -IncludeLinux

    Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    Write-ScreenInfo -Message ("Setting up the lab took {0} hour$hoursPlural, {1} minute$minutesPlural and {2} second$secondsPlural" -f $ts.hours, $ts.minutes, $ts.seconds)
    Write-ScreenInfo -Message "Lab name is '$($lab.Name)' and is hosted on '$($lab.DefaultVirtualizationEngine)'. There are $($machines.Count) machine(s) and $($lab.VirtualNetworks.Count) network(s) defined."

    if (-not $Detailed)
    {
        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    }
    else
    {
        Write-ScreenInfo -Message '----------------------------- Network Summary -----------------------------'
        $networkInfo = $lab.VirtualNetworks | Format-Table -Property Name, AddressSpace, SwitchType, AdapterName, @{ Name = 'IssuedIpAddresses'; Expression = { $_.IssuedIpAddresses.Count } } | Out-String
        $networkInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }

        Write-ScreenInfo -Message '----------------------------- Domain Summary ------------------------------'
        $domainInfo = $lab.Domains | Format-Table -Property Name,
        @{ Name = 'Administrator'; Expression = { $_.Administrator.UserName } },
        @{ Name = 'Password'; Expression = { $_.Administrator.Password } },
        @{ Name = 'RootDomain'; Expression = { if ($lab.GetParentDomain($_.Name).Name -ne $_.Name) { $lab.GetParentDomain($_.Name) } } } |
        Out-String

        $domainInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }

        Write-ScreenInfo -Message '------------------------- Virtual Machine Summary -------------------------'
        $vmInfo = Get-LabVM -IncludeLinux | Format-Table -Property Name, DomainName, IpV4Address, Roles, OperatingSystem,
        @{ Name = 'Local Admin'; Expression = { $_.InstallationUser.UserName } },
        @{ Name = 'Password'; Expression = { $_.InstallationUser.Password } } -AutoSize |
        Out-String

        $vmInfo -split "`n" | ForEach-Object {
            if ($_) { Write-ScreenInfo -Message $_ }
        }

        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
        Write-ScreenInfo -Message 'Please use the following cmdlets to interact with the machines:'
        Write-ScreenInfo -Message '- Get-LabVMStatus, Get, Start, Restart, Stop, Wait, Connect, Save-LabVM and Wait-LabVMRestart (some of them provide a Wait switch)'
        Write-ScreenInfo -Message '- Invoke-LabCommand, Enter-LabPSSession, Install-LabSoftwarePackage and Install-LabWindowsFeature (do not require credentials and'
        Write-ScreenInfo -Message '  work the same way with Hyper-V and Azure)'
        Write-ScreenInfo -Message '- Checkpoint-LabVM, Restore-LabVMSnapshot and Get-LabVMSnapshot (only for Hyper-V)'
        Write-ScreenInfo -Message '- Get-LabInternetFile downloads files from the internet and places them on LabSources (locally or on Azure)'
        Write-ScreenInfo -Message '---------------------------------------------------------------------------'
    }
}
