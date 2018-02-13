function Export-UnattendedKickstartFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $script:un += '%post'
    $script:un += 'curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo'
    $script:un += 'yum install -y powershell'
    $script:un += 'yum install -y omi-psrp-server'
    $script:un += '%end'
    ($script:un | Out-String) -replace "`r`n","`n" | Set-Content -Path $Path -Force
}