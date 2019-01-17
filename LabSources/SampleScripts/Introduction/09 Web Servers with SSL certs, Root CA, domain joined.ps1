#The is almost the same like '07 Standalone Root CA, Sub Ca domain joined.ps1' but this adds a web server and requests
#a web sever certificate for SSL. This certificate is then used for the SSL binding.

New-LabDefinition -Name LabSsl1 -DefaultVirtualizationEngine HyperV

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}

Add-LabMachineDefinition -Name DC1 -Roles RootDC

Add-LabMachineDefinition -Name CA1 -Roles CaRoot

Add-LabMachineDefinition -Name Web1 -Roles WebServer

Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Pro'

Install-Lab

Enable-LabCertificateAutoenrollment -Computer -User -CodeSigning

$cert = Request-LabCertificate -Subject CN=web1.contoso.com -TemplateName WebServer -ComputerName Web1 -PassThru

Invoke-LabCommand -ActivityName 'Setup SSL Binding' -ComputerName Web1 -ScriptBlock {
    New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https
    Import-Module -Name WebAdministration
    Get-Item -Path "Cert:\LocalMachine\My\$($args[0].Thumbprint)" | New-Item -Path IIS:\SslBindings\0.0.0.0!443
} -ArgumentList $cert

Show-LabDeploymentSummary -Detailed
