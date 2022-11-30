$null = mkdir D:\AL

$ProgressPreference = 'SilentlyContinue'

foreach ($hypervisor in 'HyperV','Az')
{
    $labname = "Integrator$($hypervisor)$($PSVersionTable.PSVersion.Major)$($PSVersionTable.PSVersion.Minor)"
    New-LabDefinition -Name $labname -DefaultVirtualizationEngine $hypervisor -VmPath D:\AL
    if ($hypervisor -eq 'Az')
    {
        Add-LabAzureSubscription -DefaultLocationName 'West Europe'
    }

    # These tests should eventually cover EVERY role, so that Invoke-LabPester creates a valid test file
    # They should also cover every combination of Operating Systems
    # One idea would be to create several labs and have them run as jobs, hopefully working as intended
    Add-LabMachineDefinition -Name DC1 -Memory 1GB -OperatingSystem 'Windows Server 2022 Datacenter' -Roles RootDC -DomainName contoso.com
    Add-LabMachineDefinition -Name CL1 -Memory 1GB -OperatingSystem 'Windows Server 2022 Datacenter' -DomainName contoso.com

    Install-Lab -NoValidation

    Invoke-LabPester -OutputFile "C:\TestResult$($hypervisor)$($labname).xml" -LabName $labname -ErrorAction SilentlyContinue
}
