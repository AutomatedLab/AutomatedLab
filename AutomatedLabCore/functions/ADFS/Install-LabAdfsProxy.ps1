function Install-LabAdfsProxy
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    Write-ScreenInfo -Message 'Configuring ADFS roles...'

    $lab = Get-Lab

    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first' -Type Warning
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role ADFSProxy

    if (-not $machines)
    {
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName ADFSProxy -Wait -ProgressIndicator 15

    $labAdfsProxies = Get-LabVM -Role ADFSProxy
    $job = Install-LabWindowsFeature -ComputerName $labAdfsProxies -FeatureName Web-Application-Proxy -AsJob -PassThru
    Wait-LWLabJob -Job $job

    Write-ScreenInfo "Installing the ADFS Proxy Servers '$($labAdfsProxies -join ',')'" -Type Info
    foreach ($labAdfsProxy in $labAdfsProxies)
    {
        Write-PSFMessage "Installing ADFS Proxy on '$labAdfsProxy'"
        $adfsProxyRole = $labAdfsProxy.Roles | Where-Object Name -eq ADFSProxy
        $adfsFullName = $adfsProxyRole.Properties.AdfsFullName
        $adfsDomainName = $adfsProxyRole.Properties.AdfsDomainName
        Write-PSFMessage "ADFS Full Name is '$adfsFullName'"

        $someAdfsServer = Get-LabVM -Role ADFS | Where-Object DomainName -eq $adfsDomainName | Get-Random
        Write-PSFMessage "Getting certificate from some ADFS server '$someAdfsServer'"
        $cert = Get-LabCertificate -ComputerName $someAdfsServer -DnsName $adfsFullName
        if (-not $cert)
        {
            Write-Error "Could not get certificate from '$someAdfsServer'. Cannot continue with ADFS Proxy setup."
            return
        }
        Write-PSFMessage "Got certificate with thumbprint '$($cert.Thumbprint)'"

        Write-PSFMessage "Adding certificate to '$labAdfsProxy'"
        $cert | Add-LabCertificate -ComputerName $labAdfsProxy

        $certThumbprint = $cert.Thumbprint
        $cred = ($lab.Domains | Where-Object Name -eq $adfsDomainName).GetCredential()

        $null = Invoke-LabCommand -ActivityName 'Configuring ADFS Proxy Servers' -ComputerName $labAdfsProxy -ScriptBlock {
            Install-WebApplicationProxy -FederationServiceTrustCredential $cred -CertificateThumbprint $certThumbprint -FederationServiceName $adfsFullName
        } -Variable (Get-Variable -Name certThumbprint, cred, adfsFullName) -PassThru

    }

    Write-LogFunctionExit
}
