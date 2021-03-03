param
(
    [Parameter(Mandatory)]
    [string]
    $ComputerName
)

$lab = Get-Lab
$vm = Get-LabVm -ComputerName $ComputerName
$cert = 'none'

if (Get-LabVm -Role CaRoot)
{
    $sans = @(
        $ComputerName
    )
    if ($lab.DefaultVirtualizationEngine -eq 'Azure')
    {
        $sans += $vm.AzureConnectionInfo.DnsName
    }

    $cert = Request-LabCertificate -Computer $ComputerName -Subject "CN=$($vm.Fqdn)" -SAN $sans -TemplateName WebServer -PassThru
}

Install-LabWindowsFeature -ComputerName $vm -IncludeManagementTools WindowsPowerShellWebAccess, Web-WebServer, Web-Application-Proxy, Web-Health, Web-Performance, Web-Security, Web-App-Dev, Web-Ftp-Server, Web-Metabase, Web-Lgcy-Scripting, Web-WMI, Web-Scripting-Tools, Web-Mgmt-Service, Web-WHC -NoDisplay

if ($lab.DefaultVirtualizationEngine -eq 'Azure')
{
    $lab.AzureSettings.LoadBalancerPortCounter++
    $remotePort = $lab.AzureSettings.LoadBalancerPortCounter
    Add-LWAzureLoadBalancedPort -Port $remotePort -DestinationPort 443 -ComputerName $vm
}

Invoke-LabCommand -ComputerName $vm -ScriptBlock {
    Get-WebSite -Name 'Default Web Site' -ErrorAction SilentlyContinue | Remove-WebSite
    $null = New-WebSite -Name pswa -PhysicalPath C:\inetpub\wwwroot
    if (-not $cert.ThumbPrint)
    {
        $cert = New-SelfSignedCertificate -Subject "CN=$env:COMPUTERNAME" -Type SSLServerAuthentication -CertStoreLocation cert:\LocalMachine\my
    }

    New-WebBinding -Name pswa -Protocol https -Port 443
    (Get-WebBinding -Name pswa).AddSslCertificate($cert.ThumbPrint, 'My')

    $null = Install-PswaWebApplication -WebSiteName pswa
    $null = Add-PswaAuthorizationRule -UserName * -ComputerName * -ConfigurationName *
} -Variable (Get-Variable cert) -NoDisplay

$hostname, $port = if ($lab.DefaultVirtualizationEngine -eq 'Azure') { $vm.AzureConnectionInfo.DnsName, $remotePort } else { $vm.Fqdn, 443 }
Write-ScreenInfo -Message ('PowerShell Web Access can be accessed using: https://{0}:{1}/pswa' -f $hostname, $port)
