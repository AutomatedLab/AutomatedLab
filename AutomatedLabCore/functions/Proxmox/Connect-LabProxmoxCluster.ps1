function Connect-LabProxmoxCluster
{
    [CmdletBinding(DefaultParameterSetName = 'CredentialConnection')]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'CredentialConnection')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TokenConnection')]
        [string]$HostName,

        [Parameter(Mandatory = $true, ParameterSetName = 'CredentialConnection')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TokenConnection')]
        [int]$Port,

        [Parameter(Mandatory = $true, ParameterSetName = 'CredentialConnection')]
        [System.Management.Automation.PSCredential]$Credential,

        # Proxmox API token in the format USER@REALM!TOKENID=UUID
        [Parameter(Mandatory = $true, ParameterSetName = 'TokenConnection')]
        [ValidateNotNullOrEmpty()]
        [string]$ApiToken,

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
    elseif ($PSCmdlet.ParameterSetName -eq 'TokenConnection')
    {
        if ($ApiToken -notmatch '^[^@\s]+@[^!\s]+![^=\s]+=[^\s]+$')
        {
            Write-Error -Message "ApiToken '$ApiToken' is not in the expected format 'USER@REALM!TOKENID=UUID'."
            return
        }

        Write-ScreenInfo -Message "Storing Proxmox cluster connection data (API token) for '$($HostName):$($Port)'" -Type Verbose
        $script:connectionData = @{
            HostName = $HostName
            Port     = $Port
            ApiToken = $ApiToken
        }
    }
    else
    {
        Write-ScreenInfo -Message "Storing Proxmox cluster connection data for '$($HostName):$($Port)'" -Type Verbose
        $script:connectionData = @{
            HostName   = $HostName
            Port       = $Port
            Credential = $Credential
        }
    }

    try
    {
        Write-ScreenInfo -Message "Connecting to Proxmox cluster at '$($script:connectionData.HostName):$($script:connectionData.Port)'" -Type Verbose

        if ($script:connectionData.ContainsKey('ApiToken'))
        {
            Connect-PveCluster -HostsAndPorts "$($script:connectionData.HostName):$($script:connectionData.Port)" -ApiToken $script:connectionData.ApiToken -SkipCertificateCheck | Out-Null
        }
        else
        {
            Connect-PveCluster -HostsAndPorts "$($script:connectionData.HostName):$($script:connectionData.Port)" -Credential $script:connectionData.Credential -SkipCertificateCheck | Out-Null
        }

        $script:connectionData.TicketTimestamp = Get-Date
        Write-ScreenInfo -Message "Successfully connected to Proxmox cluster at '$($script:connectionData.HostName):$($script:connectionData.Port)'" -Type Verbose
    }
    catch
    {
        Write-Error -Message "Failed to connect to Proxmox cluster at '$($script:connectionData.HostName):$($script:connectionData.Port)': $($_.Exception.Message)" -Exception $_.Exception
    }
}
