function Install-LabSshKnownHost
{
    [CmdletBinding()]
    param ( )

    $lab = Get-Lab
    if (-not $lab)
    {
        return
    }

    $machines = Get-LabVM -All -IncludeLinux | Where-Object -FilterScript { -not $_.SkipDeployment }
    if (-not $machines)
    {
        return
    }

    if (-not (Test-Path -Path $home/.ssh/known_hosts)) {$null = New-Item -ItemType File -Path $home/.ssh/known_hosts -Force}
    $knownHostContent = Get-LabSshKnownHost

    foreach ($machine in $machines)
    {
        if ((Get-LabVmStatus -ComputerName $machine) -ne 'Started' ) {continue}
        if ($lab.DefaultVirtualizationEngine -eq 'Azure')
        {
            $keyScanHosts = ssh-keyscan -p $machine.LoadBalancerSshPort $machine.AzureConnectionInfo.DnsName 2>$null | ConvertFrom-String -Delimiter ' ' -PropertyNames ComputerName,Cipher,Fingerprint -ErrorAction SilentlyContinue
            $keyScanIps = ssh-keyscan -p $machine.LoadBalancerSshPort $machine.AzureConnectionInfo.VIP 2>$null | ConvertFrom-String -Delimiter ' ' -PropertyNames ComputerName,Cipher,Fingerprint -ErrorAction SilentlyContinue

            foreach ($keyScanHost in $keyScanHosts)
            {
                $sshHostEntry = $knownHostContent | Where-Object {$_.ComputerName -eq "[$($machine.AzureConnectionInfo.DnsName)]:$($machine.LoadBalancerSshPort)" -and $_.Cipher -eq $keyScanHost.Cipher}
                if (-not $sshHostEntry -or $keyScanHost.Fingerprint -ne $sshHostEntry.Fingerprint)
                {
                    Write-ScreenInfo -Type Verbose -Message ("Adding line to $home/.ssh/known_hosts: {0} {1} {2}" -f $keyScanHost.ComputerName,$keyScanHost.Cipher,$keyScanHost.Fingerprint)
                    try
                    {
                        '{0} {1} {2}' -f $keyScanHost.ComputerName,$keyScanHost.Cipher,$keyScanHost.Fingerprint | Add-Content $home/.ssh/known_hosts -ErrorAction Stop
                    }
                    catch
                    {
                        Start-Sleep -Milliseconds 125
                        '{0} {1} {2}' -f $keyScanHost.ComputerName,$keyScanHost.Cipher,$keyScanHost.Fingerprint | Add-Content $home/.ssh/known_hosts
                    }
                }
            }

            foreach ($keyScanIp in $keyScanIps)
            {
                $sshHostEntryIp = $knownHostContent | Where-Object {$_.ComputerName -eq "[$($machine.AzureConnectionInfo.VIP)]:$($machine.LoadBalancerSshPort)" -and $_.Cipher -eq $keyScanIp.Cipher}
                if (-not $sshHostEntryIp -or $keyScanIp.Fingerprint -ne $sshHostEntryIp.Fingerprint)
                {
                    Write-ScreenInfo -Type Verbose -Message ("Adding line to $home/.ssh/known_hosts: {0} {1} {2}" -f $keyScanIp.ComputerName,$keyScanIp.Cipher,$keyScanIp.Fingerprint)
                    try
                    {
                        '{0} {1} {2}' -f $keyScanIp.ComputerName,$keyScanIp.Cipher,$keyScanIp.Fingerprint | Add-Content $home/.ssh/known_hosts -ErrorAction Stop
                    }
                    catch
                    {
                        Start-Sleep -Milliseconds 125
                        '{0} {1} {2}' -f $keyScanIp.ComputerName,$keyScanIp.Cipher,$keyScanIp.Fingerprint | Add-Content $home/.ssh/known_hosts
                    }
                }
            }
        }
        else
        {
            $keyScanHosts = ssh-keyscan -T 1 $machine.Name 2>$null | ConvertFrom-String -Delimiter ' ' -PropertyNames ComputerName,Cipher,Fingerprint -ErrorAction SilentlyContinue
            foreach ($keyScanHost in $keyScanHosts)
            {
                $sshHostEntry = $knownHostContent | Where-Object {$_.ComputerName -eq $machine.Name -and $_.Cipher -eq $keyScanHost.Cipher}
                if (-not $sshHostEntry -or $keyScanHost.Fingerprint -ne $sshHostEntry.Fingerprint)
                {
                    Write-ScreenInfo -Type Verbose -Message ("Adding line to $home/.ssh/known_hosts: {0} {1} {2}" -f $keyScanHost.ComputerName,$keyScanHost.Cipher,$keyScanHost.Fingerprint)
                    try
                    {
                        '{0} {1} {2}' -f $keyScanHost.ComputerName,$keyScanHost.Cipher,$keyScanHost.Fingerprint | Add-Content $home/.ssh/known_hosts -ErrorAction Stop
                    }
                    catch
                    {
                        Start-Sleep -Milliseconds 125
                        '{0} {1} {2}' -f $keyScanHost.ComputerName,$keyScanHost.Cipher,$keyScanHost.Fingerprint | Add-Content $home/.ssh/known_hosts
                    }
                }
            }
            if ($machine.IpV4Address)
            {
                $keyScanIps = ssh-keyscan -T 1 $machine.IpV4Address 2>$null | ConvertFrom-String -Delimiter ' ' -PropertyNames ComputerName,Cipher,Fingerprint -ErrorAction SilentlyContinue
                foreach ($keyScanIp in $keyScanIps)
                {
                    $sshHostEntryIp = $knownHostContent | Where-Object {$_.ComputerName -eq $machine.IpV4Address -and $_.Cipher -eq $keyScanIp.Cipher}
                    if (-not $sshHostEntryIp -or $keyScanIp.Fingerprint -ne $sshHostEntryIp.Fingerprint)
                    {
                        Write-ScreenInfo -Type Verbose -Message ("Adding line to $home/.ssh/known_hosts: {0} {1} {2}" -f $keyScanIp.ComputerName,$keyScanIp.Cipher,$keyScanIp.Fingerprint)
                        try
                        {
                            '{0} {1} {2}' -f $keyScanIp.ComputerName,$keyScanIp.Cipher,$keyScanIp.Fingerprint | Add-Content $home/.ssh/known_hosts -ErrorAction Stop
                        }
                        catch
                        {
                            Start-Sleep -Milliseconds 125
                            '{0} {1} {2}' -f $keyScanIp.ComputerName,$keyScanIp.Cipher,$keyScanIp.Fingerprint | Add-Content $home/.ssh/known_hosts
                        }
                    }
                }
            }
        }
    }
}
