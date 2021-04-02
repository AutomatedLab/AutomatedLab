function Export-UnattendedKickstartFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $idx = $script:un.IndexOf('%post')

    if ($idx -eq -1)
    {
        $script:un.Add('%post')
        $idx = $script:un.IndexOf('%post')
    }

    $repoIp = (Resolve-DnsName -Name packages.microsoft.com -Type A).IP4Address
    $repoContent = (Invoke-RestMethod -Method Get -Uri 'https://packages.microsoft.com/config/rhel/7/prod.repo' -ErrorAction SilentlyContinue) -split "`n"
    if ($script:un[$idx + 1] -ne '#start')
    {
        @(
            '#start'
            'echo "nameserver 192.168.2.121" >> /etc/resolv.conf'
            'systemctl restart NetworkManager'
            foreach ($line in $repoContent)
            {
                if (-not $line) { continue }
                'echo "{0}" >> /etc/yum.repos.d/microsoft.repo' -f $line.Replace('packages.microsoft.com', $repoIp)
            }
            'yum install -y openssl'
            'yum install -y omi'
            'yum install -y powershell'
            'yum install -y omi-psrp-server'
            'yum list installed "powershell" > /ksPowerShell'
            'yum list installed "omi-psrp-server" > /ksOmi'
            'rm /etc/yum.repos.d/microsoft.repo'
            foreach ($line in $repoContent)
            {
                if (-not $line) { continue }
                'echo "{0}" >> /etc/yum.repos.d/microsoft.repo' -f $line
            }
            'authselect select sssd with-mkhomedir -f'
            'systemctl restart sssd'
            'echo "Subsystem powershell /usr/bin/pwsh -sshs -NoLogo" >> /etc/ssh/sshd_config'
            'systemctl restart sshd'
        ) | ForEach-Object -Process {
            $idx++
            $script:un.Insert($idx, $_)
        }

        # When index of end is greater then index of package end: add %end to EOF
        # else add %end before %packages

        $idxPackage = $script:un.IndexOf('%packages --ignoremissing')
        $idxPost = $script:un.IndexOf('%post')

        $idxEnd = if (-1 -ne $idxPackage -and $idxPost -lt $idxPackage)
        {
            $idxPackage
        }
        else
        {
            $script:un.Count
        }

        $script:un.Insert($idxEnd, '%end')
    }

    ($script:un | Out-String) -replace "`r`n", "`n" | Set-Content -Path $Path -Force
}
