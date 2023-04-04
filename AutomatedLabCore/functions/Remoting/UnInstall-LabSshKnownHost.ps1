function UnInstall-LabSshKnownHost
{
    [CmdletBinding()]
    param ( )

    if (-not (Test-Path -Path $home/.ssh/known_hosts)) { return }

    $lab = Get-Lab
    if (-not $lab) { return }

    $machines = Get-LabVM -All -IncludeLinux | Where-Object -FilterScript { -not $_.SkipDeployment }
    if (-not $machines) { return }

    $content = Get-Content -Path $home/.ssh/known_hosts
    foreach ($machine in $machines)
    {
        if ($lab.DefaultVirtualizationEngine -eq 'Azure')
        {
            $content = $content | Where {$_ -notmatch "$($machine.AzureConnectionInfo.DnsName.Replace('.','\.'))"}
            $content = $content | Where {$_ -notmatch "$($machine.AzureConnectionInfo.VIP.Replace('.','\.'))"}
        }
        else
        {
            $content = $content | Where {$_ -notmatch "$($machine.Name)\s.*"}
            if ($machine.IpV4Address)
            {
                $content = $content | Where {$_ -notmatch "$($machine.Ipv4Address.Replace('.','\.'))"}
            }
        }
    }
    $content | Set-Content -Path $home/.ssh/known_hosts
}
