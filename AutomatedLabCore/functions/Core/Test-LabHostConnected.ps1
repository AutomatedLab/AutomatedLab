function Test-LabHostConnected
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingComputerNameHardcoded", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("ALSimpleNullComparison", "", Justification="We want a boolean")]
    [CmdletBinding()]
    param
    (
        [switch]
        $Throw,

        [switch]
        $Quiet
    )

    if (Get-LabConfigurationItem -Name DisableConnectivityCheck)
    {
        $script:connected = $true
    }

    if (-not $script:connected)
    {
        $script:connected = if (Get-Command Get-NetConnectionProfile -ErrorAction SilentlyContinue)
        {
            $null -ne (Get-NetConnectionProfile | Where-Object {$_.IPv4Connectivity -eq 'Internet' -or $_.IPv6Connectivity -eq 'Internet'})
        }
        elseif ((Get-ChildItem -Path env:\ACC_OID,env:\ACC_VERSION,env:\ACC_TID -ErrorAction SilentlyContinue).Count -eq 3)
        {
            # Assuming that we are in Azure Cloud Console aka Cloud Shell which is connected but cannot send ICMP packages
            $true
        }
        elseif ($IsLinux)
        {
            # Due to an unadressed issue with Test-Connection on Linux
            $portOpen = Test-Port -ComputerName automatedlab.org -Port 443
            if (-not $portOpen.Open)
            {
                [System.Net.NetworkInformation.Ping]::new().Send('automatedlab.org').Status -eq 'Success'
            }
            else
            {
                $portOpen.Open
            }
        }
        else
        {
            Test-Connection -ComputerName automatedlab.org -Count 4 -Quiet -ErrorAction SilentlyContinue -InformationAction Ignore
        }
    }

    if ($Throw.IsPresent -and -not $script:connected)
    {
        throw "$env:COMPUTERNAME does not seem to be connected to the internet. All internet-related tasks will fail."
    }

    if ($Quiet.IsPresent)
    {
        return
    }

    $script:connected
}
