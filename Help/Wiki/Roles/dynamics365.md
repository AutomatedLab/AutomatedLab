# Dynamics 365

AutomatedLab is capable of deploying Dynamics 365 either as a full installation or using the
groups Frontend, Backend and Administration. Deploying Dynamics 365 in a lab requires a
fitting SQL machine, a domain environment and ideally a certificate authority.

All required Active Directory OUs, users and groups will be automatically created
and group membership configured as outlined in [the official docs](https://docs.microsoft.com/en-us/dynamics365/customerengagement/on-premises/deploy/install-or-upgrade-microsoft-dynamics-365-server).

## Sample script

For a bare-bones sample script, have a look at the following code:  

```powershell
New-LabDefinition -name dynamics -DefaultVirtualizationEngine HyperV
Add-LabDomainDefinition contoso.com -AdminUser Install -AdminPassword Somepass1
Set-LabInstallationCredential -Username Install -Password Somepass1
Add-LabIsoImageDefinition -name SQLServer2017 -Path $labsources/ISOs/en_sql_server_2017_enterprise_x64_dvd_11293666.iso
Add-LabMachineDefinition -Name DDC1 -Memory 4GB -Roles RootDc,CARoot -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'
Add-LabMachineDefinition -Name DDB1 -Memory 8GB -Roles SQLServer2017 -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'
Add-LabMachineDefinition -Name DDY1 -Memory 16GB -Roles DynamicsFull -Domain contoso.com -OperatingSystem 'Windows Server 2019 Datacenter (Desktop Experience)'
Install-Lab
```

## Role properties

In order to specify installation parameters, you can use the `Properties` parameter
of the `Get-LabMachineRoleDefinition` cmdlet. All four roles, `DynamicsFull`, 
`DynamicsFrontend`, `DynamicsBackend`, `DynamicsAdmin` support the same set of properties.

- LicenseKey: Supply your own license key, otherwise a trial license will be used
- SqlServer: Server name (optionally include the instance) of a SQL Server that is part of the lab
- ReportingUrl: If using reporting services, specify the URL
- OrganizationCollation: Collation for the database that is created
- IsoCurrencyCode: The three-letter ISO currency code, e.g. USD
- CurrencyName: Currency name, arbitrary
- CurrencySymbol: Currency symbol, arbitrary
- CurrencyPrecision: Precision, between 2 and 4
- Organization: Friendly name of the organization
- OrganizationUniqueName: Organization name part of the URL, max 30 characters
- CrmServiceAccount: AppPool identity
- SandboxServiceAccount: Sandbox processing svc
- DeploymentServiceAccount: Deployment svc
- AsyncServiceAccount: Async processing
- VSSWriterServiceAccount: VSS writer svc
- MonitoringServiceAccount: Monitoring svc
- CrmServiceAccountPassword: Plaintext string
- SandboxServiceAccountPassword: Plaintext string
- DeploymentServiceAccountPassword: Plaintext string
- AsyncServiceAccountPassword: Plaintext string
- VSSWriterServiceAccountPassword: Plaintext string
- MonitoringServiceAccountPassword: Plaintext string
- IncomingExchangeServer: Specify an Exchange server part of the lab to configure incoming mail
- PrivUserGroup: Distinguished name of the privileged user group. Domain-DN is replaced with lab domain/machine domain
- SQLAccessGroup: Group accessing the SQL server. Domain-DN is replaced with lab domain/machine domain
- ReportingGroup: Distinguished name of the reporting group. Domain-DN is replaced with lab domain/machine domain
- PrivReportingGroup: Distinguished name of the privileged reporting group. Domain-DN is replaced with lab domain/machine domain