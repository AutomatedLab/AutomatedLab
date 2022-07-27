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

    $repoIp = try {
        ([System.Net.Dns]::GetHostByName('packages.microsoft.com').AddressList | Where-Object AddressFamily -eq InterNetwork).IPAddressToString
    }
    catch
    { '104.214.230.139' }

    try
    {
        $repoContent = (Invoke-RestMethod -Method Get -Uri 'https://packages.microsoft.com/config/rhel/7/prod.repo' -ErrorAction Stop) -split "`n"
    }
    catch { }

    if ($script:un[$idx + 1] -ne '#start')
    {
        @(
            '#start'
            '. /etc/os-release'
            foreach ($line in $repoContent)
            {
                if (-not $line) { continue }
                if ($line -like '*gpgcheck*') {$line = 'gpgcheck=0'}
                'echo "{0}" >> /etc/yum.repos.d/microsoft.repo' -f $line
            }
            'echo "{0} packages.microsoft.com" >> /etc/hosts' -f $repoIp
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
