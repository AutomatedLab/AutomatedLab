function New-LabAzureCertificate
{
    [CmdletBinding()]
    param ()
    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry

    Update-LabAzureSettings

    $certSubject = "CN=$($Script:lab.Name).cloudapp.net"
    $service = Get-LabAzureDefaultResourceGroup
    $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -eq $certSubject -ErrorAction SilentlyContinue

    if (-not $cert)
    {
        $temp = [System.IO.Path]::GetTempFileName()

        #not required as SSL is not used yet
        #& 'C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Bin\makecert.exe' -r -pe -n $certSubject -b 01/01/2000 -e 01/01/2036 -eku 1.3.6.1.5.5.7.3.1, 1.3.6.1.5.5.7.3.2 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 $temp

        certutil.exe -addstore -f Root $temp | Out-Null

        Remove-Item -Path $temp

        $cert = Get-ChildItem Cert:\LocalMachine\Root | Where-Object Subject -eq $certSubject
    }

    #not required as SSL is not used yet
    #$service | Add-AzureCertificate -CertToDeploy (Get-Item -Path "Cert:\LocalMachine\Root\$($cert.Thumbprint)")
}
