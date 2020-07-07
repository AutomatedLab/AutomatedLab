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

    if ($script:un[$idx + 1] -ne '#start')
    {
        @(
            '#start'
            'curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo'
            'yum install -y openssl'
            'yum install -y omi'
            'yum install -y powershell'
            'yum install -y omi-psrp-server'
            'yum list installed "powershell" > /tmp/ksPowerShell'
            'yum list installed "omi-psrp-server" > /tmp/ksOmi'
            'authselect sssd with-mkhomedir'
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
