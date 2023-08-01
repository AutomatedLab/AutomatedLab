function Uninstall-LabRdsCertificate
{
    [CmdletBinding()]
    param ( )

    $lab = Get-Lab
    if (-not $lab)
    {
        return
    }

    foreach ($certFile in (Get-ChildItem -File -Path (Join-Path -Path $lab.LabPath -ChildPath Certificates) -Filter *.cer -ErrorAction SilentlyContinue))
    {
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certFile.FullName)
        if ($cert.Thumbprint)
        {
            Get-Item -Path ('Cert:\LocalMachine\Root\{0}' -f $cert.Thumbprint) | Remove-Item
        }

        $certFile | Remove-Item
    }
}
