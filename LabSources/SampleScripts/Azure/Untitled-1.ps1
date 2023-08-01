$Gateway = Get-AzVirtualNetworkGateway -ResourceGroupName projectdagger -Name Bifrost
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $Gateway -VpnClientAddressPool '10.2.0.0/24'

$filePathForCert = "C:\tmp\RootCaSelfSigned.cer"
$cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($filePathForCert)
$CertBase64 = [system.convert]::ToBase64String($cert.RawData)
Add-AzVpnClientRootCertificate -VpnClientRootCertificateName 'P2SRootCaSelfSigned' -VirtualNetworkGatewayname Bifrost -ResourceGroupName projectdagger -PublicCertData $CertBase64

$cert = Get-ChildItem Cert:\CurrentUser\my | where Subject -eq 'CN=P2SRootCert'
foreach ($name in ('joshua', 'christoph', 'thomas'))
{
    New-SelfSignedCertificate -Type Custom -DnsName $name -KeySpec Signature `
        -Subject "CN=$name" -KeyExportPolicy Exportable `
        -HashAlgorithm sha256 -KeyLength 2048 `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2") | Export-PfxCertificate -FilePath "C:\tmp\$name.pfx" -Password ('555nase' | ConvertTo-SecureString -AsPlainText -Force)
}

$profile = get-AzVpnClientConfiguration -ResourceGroupName projectdagger -Name Bifrost
if (-not $profile)
{
    $profile = New-AzVpnClientConfiguration -ResourceGroupName projectdagger -Name Bifrost -AuthenticationMethod "EapTls"
}
Invoke-RestMethod $profile.VPNProfileSASUrl -OutFile C:\tmp\vpn.zip

foreach ($item in 'cppredist64_2017','cppredist64_2012','SharePoint2019Prerequisites')
{
foreach ($file in (Get-LabConfigurationItem -Name $item))
{
    if ($item -eq 'cppredist64_2017') {
        Get-LabInternetFile -Uri $file -Path C:\LabSources\SoftwarePackages -FileName vc_redist.x64.exe
        continue
    }
    elseif ($item -eq 'cppredist64_2012')
    {
        Get-LabInternetFile -Uri $file -Path C:\LabSources\SoftwarePackages -FileName vc11redist_x64.exe
        continue
    }
    Get-LabInternetFile -Uri $file -Path C:\LabSources\SoftwarePackages
}
}