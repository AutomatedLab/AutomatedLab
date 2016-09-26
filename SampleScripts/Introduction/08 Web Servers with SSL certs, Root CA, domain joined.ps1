#The is almost the same like '07 Standalone Root CA, Sub Ca domain joined.ps1' but this adds a web server and requests
#a web sever certificate for SSL.

New-LabDefinition -Name 'Lab1' -DefaultVirtualizationEngine HyperV

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 SERVERDATACENTER'
}

Add-LabMachineDefinition -Name DC1 -Roles RootDC

Add-LabMachineDefinition -Name CA1 -Roles CaRoot

Add-LabMachineDefinition -Name Web1 -Roles WebServer

Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Pro'

Install-Lab

Enable-LabCertificateAutoenrollment -Computer -User -CodeSigning

Request-LabCertificate -Subject CN=web1.contoso.com -TemplateName WebServer -ComputerName Web1

Show-LabInstallationTime