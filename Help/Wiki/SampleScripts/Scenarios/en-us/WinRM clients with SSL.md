# Scenarios - WinRM clients with SSL

INSERT TEXT HERE

```powershell
#This lab provides an environment to test WinRM authentication inside a domain and from a domain-joined client to a
#non-domain-joined client and vice versa. This lab also installs a PKI and requests an SSL certificate for each
#client, domain-joined and non-domain-joined. Hence you can connect to each machine using SSL without providing
#explicit credentials using Negotiate.
#
#For example the following commands work:
#Enter-PSSession -ComputerName wserver1
#Enter-PSSession -ComputerName wserver1.contoso.com -UseSSL
#Enter-PSSession -ComputerName wserver3 -UseSSL

New-LabDefinition -Name WinRMSslLab -DefaultVirtualizationEngine HyperV

Add-LabMachineDefinition -Name wDC1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Roles RootDC, CaRoot -Domain contoso.com
Add-LabMachineDefinition -Name wServer1 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Domain contoso.com
Add-LabMachineDefinition -Name wServer2 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -Domain contoso.com
Add-LabMachineDefinition -Name wServer3 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)'
Add-LabMachineDefinition -Name wServer4 -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)'

Install-Lab

$vms = Get-LabVM -All

Install-LabSoftwarePackage -ComputerName $vms -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $vms -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $vms -Path $labSources\SoftwarePackages\nmap-7.40-setup.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $vms -Path $labSources\SoftwarePackages\Wireshark.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

$ca = Get-LabIssuingCA | Select-Object -First 1
New-LabCATemplate -TemplateName WinRmSsl -DisplayName 'WinRm SSL' -SourceTemplateName WebServer -ApplicationPolicy 'Server Authentication' `
-EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'NT AUTHORITY\Anonymous Logon' -ComputerName $ca -ErrorAction Stop

foreach ($vm in $vms)
{
    $subject = if ($vm.DomainName)
    {
        "cn=$($vm.Name).$($vm.DomainName)"
    }
    else
    {
        "cn=$($vm.Name)"
    }

    Request-LabCertificate -Subject $subject -TemplateName WinRmSsl -ComputerName $vm -OnlineCA $ca
}

Invoke-LabCommand -ActivityName EnableSsl -ComputerName $vms -ScriptBlock {
    New-WSManInstance winrm/config/Listener	-SelectorSet @{ Address="*"; Transport="HTTPS" }
}

Show-LabDeploymentSummary -Detailed
```
