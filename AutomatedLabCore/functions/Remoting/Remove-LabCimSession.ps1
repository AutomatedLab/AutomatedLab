function Remove-LabCimSession
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]
        $ComputerName,

        [Parameter(Mandatory, ParameterSetName = 'ByMachine')]
        [AutomatedLab.Machine[]]
        $Machine,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All
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
            if (Get-LabConfigurationItem -Name DoNotUseGetHostEntryInNewLabPSSession)
            {
                $param.Add('ComputerName', $m.Name)
            }
            elseif (Get-LabConfigurationItem -Name SkipHostFileModification)
            {
                $param.Add('ComputerName', $m.IpV4Address)
            }
            else
            {
                $param.Add('ComputerName', (Get-HostEntry -Hostname $m).IpAddress.IpAddressToString)
            }
            $param.Add('Port', 5985)
        }

        Get-CimSession | Where-Object {
            $_.ComputerName -eq $param.ComputerName -and
        $_.Name -like "$($m)_*" }
    }

    $sessions | Remove-CimSession -ErrorAction SilentlyContinue

    Write-PSFMessage "Removed $($sessions.Count) PSSessions..."
    Write-LogFunctionExit
}
