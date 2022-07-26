$null = mkdir D:\AL

New-LabDefinition -Name Integrator -DefaultVirtualizationEngine HyperV -VmPath D:\AL

# These tests should eventually cover EVERY role, so that Invoke-LabPester creates a valid test file
# They should also cover every combination of Operating Systems
# One idea would be to create several labs and have them run as jobs, hopefully working as intended
Add-LabMachineDefinition -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2022 Datacenter' -Roles RootDC -DomainName contoso.com
Add-LabMachineDefinition -Name CL1 -Memory 1GB -OperatingSystem 'Windows Server 2022 Datacenter' -DomainName contoso.com

Install-Lab -NoValidation

Invoke-LabPester -OutputFile C:\Integrator.xml -LabName Integrator