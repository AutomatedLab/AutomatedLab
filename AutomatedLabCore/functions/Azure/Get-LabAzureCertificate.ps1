function Get-LabAzureCertificate
{
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    [CmdletBinding()]
    param ()

    throw New-Object System.NotImplementedException
    Write-LogFunctionEntry

    Update-LabAzureSettings

    $certSubject = "CN=$($Script:lab.Name).cloudapp.net"

    $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -eq $certSubject -ErrorAction SilentlyContinue

    if (-not $cert)
    {
        #just returning nothing is more convenient
        #Write-LogFunctionExitWithError -Message "The required certificate does not exist"
    }
    else
    {
        $cert
    }

    Write-LogFunctionExit
}
