function Remove-LabPSSession
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByMachine')]
        [AutomatedLab.Machine[]]$Machine,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    if ($PSCmdlet.ParameterSetName -eq 'ByName')
    {
        $Machine = Get-LabVM -ComputerName $ComputerName -IncludeLinux
    }
    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $Machine = Get-LabVM -All -IncludeLinux
    }

    $sessions = foreach ($m in $Machine)
    {
        $param = @{}
        if ($m.HostType -eq 'Azure')
        {
            $param.Add('ComputerName', $m.AzureConnectionInfo.DnsName)
            $param.Add('Port', $m.AzureConnectionInfo.Port)
        }
        elseif ($m.HostType -eq 'HyperV' -or $m.HostType -eq 'VMWare')
        {
            $doNotUseGetHostEntry = Get-LabConfigurationItem -Name DoNotUseGetHostEntryInNewLabPSSession
            if (-not $doNotUseGetHostEntry)
            {
                $name = (Get-HostEntry -Hostname $m).IpAddress.IpAddressToString
            }
            elseif ($doNotUseGetHostEntry -or -not [string]::IsNullOrEmpty($m.FriendlyName) -or (Get-LabConfigurationItem -Name SkipHostFileModification))
            {
                $name = $m.IpV4Address
            }
            $param['ComputerName'] = $name
            $param['Port'] = 5985
        }

        if (((Get-Command New-PSSession).Parameters.Values.Name -contains 'HostName') )
        {
            $param['HostName'] = $param['ComputerName']
            $param['Port'] = if ($m.HostType -eq 'Azure') {$m.AzureConnectionInfo.SshPort} else { 22 }
            $param.Remove('ComputerName')
            $param.Remove('PSSessionOption')
            $param.Remove('Authentication')
            $param.Remove('Credential')
            $param.Remove('UseSsl')
        }

        Get-PSSession | Where-Object {
            (($_.ComputerName -eq $param.ComputerName) -or ($_.ComputerName -eq $param.HostName)) -and
            ($_.Runspace.ConnectionInfo.Port -eq $param.Port -or ($param.HostName -and $_.Transport -eq 'SSH')) -and
        $_.Name -like "$($m)_*" }
    }

    $sessions | Remove-PSSession -ErrorAction SilentlyContinue

    Write-PSFMessage "Removed $($sessions.Count) PSSessions..."
    Write-LogFunctionExit
}
