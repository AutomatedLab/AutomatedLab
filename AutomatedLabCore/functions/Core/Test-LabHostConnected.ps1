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
        else
        {
            # Do a quick check with HEAD only, more reliable across OSes
            $response = Invoke-WebRequest -Method Head -Uri https://automatedlab.org -TimeoutSec 5 -ErrorAction SilentlyContinue
            $null -ne $response
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
