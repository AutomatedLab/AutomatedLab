#The is almost the same like '05 SQL Server and client, domain joined.ps1' but installs a Certificate Authority instead
#of a SQL Server. The CA is installed with standard settings. Customizing the CA installation will be shown later.

New-LabDefinition -Name 'Lab1' -DefaultVirtualizationEngine HyperV

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:Memory' = 1GB
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 SERVERDATACENTER'
}

Add-LabMachineDefinition -Name DC1 -Roles RootDC

Add-LabMachineDefinition -Name CA1 -Roles CaRoot

Add-LabMachineDefinition -Name Client1 -OperatingSystem 'Windows 10 Pro'

Install-Lab

Enable-LabCertificateAutoenrollment -Computer -User -CodeSigning

Show-LabDeploymentSummary -Detailed
