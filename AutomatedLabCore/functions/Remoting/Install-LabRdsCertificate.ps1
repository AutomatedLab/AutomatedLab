function Install-LabRdsCertificate
{
    [CmdletBinding()]
    param ( )

    $lab = Get-Lab
    if (-not $lab)
    {
        return
    }

    $machines = Get-LabVM -All | Where-Object -FilterScript { $_.OperatingSystemType -eq 'Windows' -and $_.OperatingSystem.Version -ge 6.3 -and -not $_.SkipDeployment }
    if (-not $machines)
    {
        return
    }

    $jobs = foreach ($machine in $machines)
    {
        Invoke-LabCommand -ComputerName $machine -ActivityName 'Exporting RDS certs' -NoDisplay -ScriptBlock {
            [string[]]$SANs = $machine.FQDN
            $cmdlet = Get-Command -Name New-SelfSignedCertificate -ErrorAction SilentlyContinue
            if ($machine.HostType -eq 'Azure' -and $cmdlet)
            {
                $SANs += $machine.AzureConnectionInfo.DnsName
            }

            $cert = if ($cmdlet.Parameters.ContainsKey('Subject'))
            {
                New-SelfSignedCertificate -Subject "CN=$($machine.Name)" -DnsName $SANs -CertStoreLocation 'Cert:\LocalMachine\My' -Type SSLServerAuthentication
            }
            else
            {
                New-SelfSignedCertificate -DnsName $SANs -CertStoreLocation 'Cert:\LocalMachine\my'
            }
            $rdsSettings = Get-CimInstance -ClassName Win32_TSGeneralSetting -Namespace ROOT\CIMV2\TerminalServices
            $rdsSettings.SSLCertificateSHA1Hash = $cert.Thumbprint
            $rdsSettings | Set-CimInstance
            $null = $cert | Export-Certificate -FilePath "C:\$($machine.Name).cer" -Type CERT -Force
        } -Variable (Get-Variable machine) -AsJob -PassThru
    }

    Wait-LWLabJob -Job $jobs -NoDisplay
    $tmp = Join-Path -Path $lab.LabPath -ChildPath Certificates
    if (-not (Test-Path -Path $tmp)) { $null = New-Item -ItemType Directory -Path $tmp }
    foreach ($session in (New-LabPSSession -ComputerName $machines))
    {
        $fPath = Join-Path -Path $tmp -ChildPath "$($session.LabMachineName).cer"
        Receive-File -SourceFilePath "C:\$($session.LabMachineName).cer" -DestinationFilePath $fPath -Session $session
        $null = Import-Certificate -FilePath $fPath -CertStoreLocation 'Cert:\LocalMachine\Root'
    }
}
