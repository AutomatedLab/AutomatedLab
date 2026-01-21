function Connect-LabProxmoxCluster
{
    [CmdletBinding(DefaultParameterSetName = 'NewConnection')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'NewConnection')]
        [string]$HostName,

        [Parameter(Mandatory = $true, ParameterSetName = 'NewConnection')]
        [int]$Port,

        [Parameter(Mandatory = $true, ParameterSetName = 'NewConnection')]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false, ParameterSetName = 'UseExistingConnection')]
        [switch]$RefreshExistingConnection
    )

    if ($PSCmdlet.ParameterSetName -eq 'UseExistingConnection' -and $RefreshExistingConnection)
    {
        if (-not $script:connectionData)
        {
            Write-Error -Message 'No existing Proxmox cluster connection data found to refresh. Call this cmdlet with connection parameters first.'
            return
        }
        Write-ScreenInfo -Message "Refreshing existing Proxmox cluster connection to '$($script:connectionData.HostName):$($script:connectionData.Port)'" -Type Verbose
    }
    else
    {
        Write-ScreenInfo -Message "Storing Proxmox cluster connection data for '$($HostName):$($Port)'" -Type Verbose
        $script:connectionData = @{
            HostName = $HostName
            Port     = $Port
            Credential = $Credential
        }
    }

    try
    {
        Write-ScreenInfo -Message "Connecting to Proxmox cluster at '$($script:connectionData.HostName):$($script:connectionData.Port)'" -Type Verbose
        Connect-PveCluster -HostsAndPorts "$($script:connectionData.HostName):$($script:connectionData.Port)" -Credential $script:connectionData.Credential -SkipCertificateCheck | Out-Null
        $script:connectionData.TicketTimestamp = Get-Date
        Write-ScreenInfo -Message "Successfully connected to Proxmox cluster at '$($script:connectionData.HostName):$($script:connectionData.Port)'" -Type Significant
    }
    catch
    {
        Write-Error -Message "Failed to connect to Proxmox cluster at '$($script:connectionData.HostName):$($script:connectionData.Port)': $($_.Exception.Message)" -Exception $_.Exception
    }
}
