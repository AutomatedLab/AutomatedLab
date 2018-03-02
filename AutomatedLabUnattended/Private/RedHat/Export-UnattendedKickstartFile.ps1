function Export-UnattendedKickstartFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $script:un += @'
    %post
    function IsNotInstalled {
        if yum list installed "$@" >/dev/null 2>&1; then
          false
        else
          true
        fi
      }
    curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
    yum install -y openssl
    yum install -y powershell
    yum install -y omi-psrp-server

    if IsNotInstalled powershell; then yum install -y powershell; fi
    if IsNotInstalled omi-psrp-server; then yum install -y powershell; fi

    yum list installed "powershell" > /tmp/ksPowerShell
    yum list installed "omi-psrp-server" > /tmp/ksOmi
    %end
'@
    ($script:un | Out-String) -replace "`r`n","`n" | Set-Content -Path $Path -Force
}