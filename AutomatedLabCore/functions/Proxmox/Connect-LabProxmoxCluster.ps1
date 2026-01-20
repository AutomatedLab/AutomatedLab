function Connect-LabProxmoxCluster {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$HostName,

        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        Write-Verbose "Connecting to Proxmox cluster at '$($HostName):$($Port)'"
        Connect-PveCluster -HostsAndPorts "$($HostName):$($Port)" -Credential $Credential -SkipCertificateCheck | Out-Null
        Write-Host "Successfully connected to Proxmox cluster at '$($HostName):$($Port)'" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Failed to connect to Proxmox cluster at '$($HostName):$($Port)': $($_.Exception.Message)" -Exception $_.Exception
    }
}
