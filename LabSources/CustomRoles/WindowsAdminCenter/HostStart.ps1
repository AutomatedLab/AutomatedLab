param
(
    [Parameter(Mandatory)]
    [string]
    $ComputerName,

    [Parameter(Mandatory)]
    [string]
    $WacDownloadLink,

    [Parameter()]
    [uint16]
    $Port = 443,

    [ValidateSet('True', 'False')]
    [string]$EnableDevMode
)

$lab = Import-Lab -Name $data.Name -NoValidation -NoDisplay -PassThru

if (-not $lab)
{
    Write-Error -Message 'Please deploy a lab first.'
    return
}

$labMachine = Get-LabVm -ComputerName $ComputerName
$wacDownload = Get-LabInternetFile -Uri $WacDownloadLink -Path "$(Get-LabSourcesLocationInternal -Local)\SoftwarePackages\WAC.msi" -PassThru -NoDisplay

if ($labMachine.IsDomainJoined -and (Get-LabIssuingCA -DomainName $labMachine.DomainName -ErrorAction SilentlyContinue) )
{
    $cert = Request-LabCertificate -Subject "CN=$($machine.FQDN)" -SAN $labMachine.Name -TemplateName WebServer -ComputerName $labMachine -PassThru -ErrorAction Stop
}

$arguments = @(
    '/qn'
    '/L*v C:\wacLoc.txt'
    "SME_PORT=$Port"
)

if ([Convert]::ToBoolean($EnableDevMode))
{
    $arguments += 'DEV_MODE=1'
}

if ($cert.Thumbprint)
{
    $arguments += "SME_THUMBPRINT=$($cert.Thumbprint)"
    $arguments += "SSL_CERTIFICATE_OPTION=installed"
}
else
{
    $arguments += "SSL_CERTIFICATE_OPTION=generate"
}

if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12') 
{
    Write-Verbose -Message 'Adding support for TLS 1.2'
    [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
}

Write-ScreenInfo -Type Verbose -Message "Starting installation of Windows Admin Center on $labMachine"
$installation = Install-LabSoftwarePackage -Path $wacDownload.Path -CommandLine $($arguments -join ' ') -ComputerName $labMachine -ExpectedReturnCodes 0, 3010 -AsJob -PassThru -NoDisplay

Write-ScreenInfo -Message "Waiting for the installation of Windows Admin Center to finish on $labMachine"
Wait-LWLabJob -Job $installation -ProgressIndicator 5 -NoNewLine -NoDisplay

if ($installation.State -eq 'Failed')
{
    Get-Job -Id $($installation.Id) | Receive-Job -Keep -ErrorAction SilentlyContinue -ErrorVariable err
    if ($err[0].Exception -is [System.Management.Automation.Remoting.PSRemotingTransportException])
    {
        Write-ScreenInfo -Type Verbose -Message "WAC setup has restarted WinRM. The setup of WAC should be completed"
        Invoke-LabCommand -ActivityName 'Waiting for WAC setup to really complete' -ComputerName $labMachine -ScriptBlock {
            while ((Get-Process -Name msiexec).Count -gt 1)
            {
                Start-Sleep -Milliseconds 250
            }
        } -NoDisplay
    }
    else
    {
        Write-ScreenInfo -Type Error -Message "Installing Windows Admin Center on $labMachine failed. Review the errors with Get-Job -Id $($installation.Id) | Receive-Job -Keep"
        return
    }
}

Restart-LabVm -ComputerName $ComputerName -Wait -NoDisplay
Write-ScreenInfo -Message "Installation of Windows Admin Center done. You can access it here: https://$($labMachine.FQDN):$Port"

# Add hosts through REST API
Write-ScreenInfo -Message "Adding $((Get-LabVm | Where-Object -Property Name -ne $ComputerName).Count) hosts to the admin center for user $($labMachine.GetCredential($lab).UserName)"
$apiEndpoint = "https://$($labmachine.FQDN):$Port/api/connections"

$bodyHash = foreach ($machine in (Get-LabVm | Where-Object -Property Name -ne $ComputerName))
{
    @{
        id   = "msft.sme.connection-type.server!$($machine.FQDN)"
        name = $machine.FQDN
        type = "msft.sme.connection-type.server"
    }
}

try
{
    $response = Invoke-RestMethod -Method PUT -Uri $apiEndpoint -Credential $labMachine.GetCredential($lab) -Body $($bodyHash | ConvertTo-Json) -ContentType application/json -ErrorAction Stop
    Write-ScreenInfo -Message "Successfully added all lab machines as connections for $($labMachine.GetCredential($lab).UserName)"
}
catch
{
    Write-ScreenInfo -type Error -Message "Could not add server connections. Invoke-RestMethod says: $($_.Exception.Message)"
}
