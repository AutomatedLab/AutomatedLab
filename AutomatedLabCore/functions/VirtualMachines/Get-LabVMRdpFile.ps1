function Get-LabVMRdpFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]
        $ComputerName,

        [Parameter()]
        [switch]
        $UseLocalCredential,

        [Parameter(ParameterSetName = 'All')]
        [switch]
        $All,

        [Parameter()]
        [string]
        $Path
    )

    if ($ComputerName)
    {
        $machines = Get-LabVM -ComputerName $ComputerName
    }
    else
    {
        $machines = Get-LabVM -All
    }

    $lab = Get-Lab
    if ([string]::IsNullOrWhiteSpace($Path))
    {
        $Path = $lab.LabPath
    }

    foreach ($machine in $machines)
    {
        Write-PSFMessage "Creating RDP file for machine '$($machine.Name)'"
        $port = 3389
        $name = $machine.Name

        if ($UseLocalCredential)
        {
            $cred = $machine.GetLocalCredential()
        }
        else
        {
            $cred = $machine.GetCredential($lab)
        }

        if ($machine.HostType -eq 'Azure')
        {
            $cn = Get-LWAzureVMConnectionInfo -ComputerName $machine
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $cn.DnsName, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null

            $name = $cn.DnsName
            $port = $cn.RdpPort
        }
        elseif ($machine.HostType -eq 'HyperV')
        {
            $cmd = 'cmdkey.exe /add:"TERMSRV/{0}" /user:"{1}" /pass:"{2}"' -f $machine.Name, $cred.UserName, $cred.GetNetworkCredential().Password
            Invoke-Expression $cmd | Out-Null
        }

        $rdpContent = @"
redirectclipboard:i:1
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
devicestoredirect:s:*
drivestoredirect:s:*
redirectdrives:i:1
session bpp:i:32
prompt for credentials on client:i:0
span monitors:i:1
use multimon:i:0
server port:i:$port
allow font smoothing:i:1
promptcredentialonce:i:0
videoplaybackmode:i:1
audiocapturemode:i:1
gatewayusagemethod:i:0
gatewayprofileusagemethod:i:1
gatewaycredentialssource:i:0
full address:s:$name
use redirection server name:i:1
username:s:$($cred.UserName)
authentication level:i:0
"@
        $filePath = Join-Path -Path $Path -ChildPath ($machine.Name + '.rdp')
        $rdpContent | Set-Content -Path $filePath
        Get-Item $filePath
        Write-PSFMessage "RDP file saved to '$filePath'"
    }
}
