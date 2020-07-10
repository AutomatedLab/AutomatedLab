$labName = 'Kerberos101'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.22.0/24
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name vm.net -AdminUser Install -AdminPassword Somepass1
Add-LabDomainDefinition -Name a.vm.net -AdminUser Install -AdminPassword Somepass2
Add-LabDomainDefinition -Name test.net -AdminUser Install -AdminPassword Somepass0

#these images are used to Install the machines
Add-LabIsoImageDefinition -Name SQLServer2014 -Path $labSources\ISOs\en_sql_server_2014_standard_edition_with_service_pack_2_x64_dvd_8961564.iso

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'= 1GB
    'Add-LabMachineDefinition:Gateway' = '192.168.22.200'
}

#========== #these credentials are used for connecting to the machines in the root doamin vm.net. ==========================
Set-LabInstallationCredential -Username Install -Password Somepass1

#The PostInstallationActivity is just creating some users
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name KerbDC1 -IpAddress 192.168.22.10 -DnsServer1 192.168.22.10  -DomainName vm.net -Roles RootDC -PostInstallationActivity $postInstallActivity

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.22.200 -Ipv4DNSServers 192.168.22.10
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name KerbRouter1 -NetworkAdapter $netAdapter -DomainName vm.net -Roles Routing

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.22.15 -Ipv4DNSServers 192.168.22.10
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name KerbLinux1 -OperatingSystem 'CentOS-7' -DomainName vm.net -NetworkAdapter $netAdapter -RhelPackage gnome-desktop

#========== #these credentials are used for connecting to the machines in the child doamin a.vm.net. ==========================
Set-LabInstallationCredential -Username Install -Password Somepass2

#this is the first domain controller of the child domain 'a' defined above
#The PostInstallationActivity is filling the domain with some life.
#At the end about 6000 users are available with OU and manager hierarchy as well as a bunch of groups
$role = Get-LabMachineRoleDefinition -Role FirstChildDC -Properties @{ ParentDomain = 'vm.net'; NewDomain = 'a' }
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
Add-LabMachineDefinition -Name KerbDC2 -IpAddress 192.168.22.11 -DnsServer1 192.168.22.10 -DnsServer2 192.168.22.11 -DomainName a.vm.net -Roles $role -PostInstallationActivity $postInstallActivity

#This is a web server in the child domain
Add-LabMachineDefinition -Name KerbWeb2 -IpAddress 192.168.22.50 -DnsServer1 192.168.22.11 -DomainName a.vm.net -Roles WebServer

#A File Server that is also the router to access the internet
Add-LabMachineDefinition -Name KerbFile2 -IpAddress 192.168.22.51 -DnsServer1 192.168.22.11 -DomainName a.vm.net -Roles FileServer

#Two SQL servers with the usual demo databases
$role = Get-LabMachineRoleDefinition -Role SQLServer2014 -Properties @{ InstallSampleDatabase = 'true' }
Add-LabMachineDefinition -Name KerbSql21 -Memory 1GB -IpAddress 192.168.22.52 -DnsServer1 192.168.22.11 -DomainName a.vm.net -Roles $role
Add-LabMachineDefinition -Name KerbSql22 -Memory 2GB -IpAddress 192.168.22.53 -DnsServer1 192.168.22.11 -DomainName a.vm.net -Roles $role

#Definition of a new Windows 10 client
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.22.55 -Ipv4DNSServers 192.168.22.11
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name KerbClient2 -Memory 2GB -NetworkAdapter $netAdapter -DomainName a.vm.net -OperatingSystem 'Windows 10 Pro'

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.22.60 -Ipv4DNSServers 192.168.22.11
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name KerbLinux2 -OperatingSystem 'CentOS-7' -DomainName a.vm.net -NetworkAdapter $netAdapter -RhelPackage gnome-desktop

#========== Now the 2nd forest gets setup with new credentials ==========================
Set-LabInstallationCredential -Username Install -Password Somepass0

#this will become the root domain controller of the second forest
#The PostInstallationActivity is just creating some users
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name KerbDC0 -IpAddress 192.168.22.100 -DnsServer1 192.168.22.100 -DomainName test.net -Roles RootDC -PostInstallationActivity $postInstallActivity

#This is a web serverin the child domain
Add-LabMachineDefinition -Name KerbWeb0 -IpAddress 192.168.22.110 -DnsServer1 192.168.22.100 -DomainName test.net -Roles WebServer

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winpcap-nmap.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Wireshark.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\MessageAnalyzer64.msi -CommandLine /Quiet -AsJob
Install-LabSoftwarePackage -ComputerName KerbClient2 -Path "$labSources\SoftwarePackages\RSAT Windows 10 x64.msu" -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Checkpoint-LabVM -All -SnapshotName AfterInstall
Show-LabDeploymentSummary -Detailed

$fileServers = Get-LabVM -Role FileServer
Install-LabWindowsFeature -FeatureName FS-SMB1 -ComputerName $fileServers -IncludeAllSubFeature
Restart-LabVM -ComputerName $fileServers -Wait

<#in server 2019 there seems to be an issue with dynamic DNS registration, doing this manually
        foreach ($domain in (Get-Lab).Domains)
        {
        $vms = Get-LabVM -All -IncludeLinux | Where-Object {
        $_.DomainName -eq $domain.Name -and
        $_.OperatingSystem -like '*2019*' -or
        $_.OperatingSystem -like '*CentOS*'
        }

        $dc = Get-LabVM -Role ADDS | Where-Object DomainName -eq $domain.Name | Select-Object -First 1

        Invoke-LabCommand -ActivityName 'Registering DNS records' -ScriptBlock {
        foreach ($vm in $vms)
        {
            if (-not (Get-DnsServerResourceRecord -Name $vm.Name -ZoneName $vm.DomainName -ErrorAction SilentlyContinue))
            {
                "Running 'Add-DnsServerResourceRecord -ZoneName $($vm.DomainName) -IPv4Address $($vm.IpV4Address) -Name $($vm.Name) -A'"
                Add-DnsServerResourceRecord -ZoneName $vm.DomainName -IPv4Address $vm.IpV4Address -Name $vm.Name -A
            }
        }
        } -ComputerName $dc -Variable (Get-Variable -Name vms) -PassThru
}#>

#Create SMB share and test file on the file server
Invoke-LabCommand -ActivityName 'Create SMB Share' -ComputerName (Get-LabVM -Role FileServer) -ScriptBlock {

    New-Item -ItemType Directory C:\Test -ErrorAction SilentlyContinue
    New-SmbShare -Name Test -Path C:\Test -FullAccess Everyone
    New-Item -Path C:\Test\TestFile.txt -ItemType File

}

#install missing packages on Linux client
Invoke-LabCommand -ActivityName 'Install packages' -ComputerName KerbLinux1 -ScriptBlock {

    sudo yum install samba-client -y
    sudo yum install cifs-utils -y
    sudo yum install krb5-workstation -y

}

#mounting the test share in the Linux client
Invoke-LabCommand -ActivityName 'Mounting test share' -ComputerName KerbLinux1 -ScriptBlock {

    sudo mkdir /test
    'Somepass1' | sudo kinit install@VM.NET

    sudo mount -t cifs -o sec=krb5 //KerbFile2.a.vm.net/Test /test --verbose

} -PassThru

Copy-LabFileItem -Path $labSources\Kerberos101 -ComputerName (Get-LabVM)

Invoke-LabCommand -ActivityName 'Installing Kerberos101 module' -ComputerName (Get-LabVM) -ScriptBlock {

    & C:\Kerberos101\Kerberos101.ps1

}

Invoke-LabCommand -ActivityName 'Enabling RDP Restricted Mode' -ComputerName (Get-LabVM) -ScriptBlock {

    Set-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\Lsa -Name DisableRestrictedAdmin -Value 0 -Type DWord
}

Checkpoint-LabVM -All -SnapshotName AfterCustomizations