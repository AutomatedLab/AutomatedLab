<#
This lab script serves the purpose of showing you how to create and connect two Azure labs in different resource groups e.g. in different locations

You will need an Azure subscription and both labs need to be created within the same subscription. Otherwise you can have a look at the other
options that Connect-Lab provides to specify the VPN gateway of the resources in another subscription
#>

# Define your labs. Make sure that the virtual network address spaces do not overlap.
$labs = @(
    @{
        LabName = 'SourceNameHere'
        AddressSpace = '192.168.50.0/24'
        Domain = 'powershell.isawesome'
        Dns1 = '192.168.50.10'
        Dns2 ='192.168.50.11'
        Location = 'West Europe'
    }
    @{
        LabName = 'DestinationNameHere'
        AddressSpace = '192.168.100.0/24'
        Domain = 'powershell.power'
        Dns1 = '192.168.100.10'
        Dns2 ='192.168.100.11'
        Location = 'East US'
    }
)

foreach ($lab in $labs.GetEnumerator())
{
    New-LabDefinition -Name $lab.LabName -DefaultVirtualizationEngine Azure

    Add-LabAzureSubscription -DefaultLocationName $lab.Location

    #make the network definition
    Add-LabVirtualNetworkDefinition -Name $lab.LabName -AddressSpace $lab.AddressSpace

    #and the domain definition with the domain admin account
    Add-LabDomainDefinition -Name $lab.Domain -AdminUser Install -AdminPassword 'P@ssw0rd'

    Set-LabInstallationCredential -Username Install -Password 'P@ssw0rd'

    #defining default parameter values, as these ones are the same for all the machines
    $PSDefaultParameterValues = @{
        'Add-LabMachineDefinition:Network' = $lab.LabName
        'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
        'Add-LabMachineDefinition:DomainName' = $lab.Domain
        'Add-LabMachineDefinition:DnsServer1' = $lab.Dns1
        'Add-LabMachineDefinition:DnsServer2' = $lab.Dns2
        'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    }

    #the first machine is the root domain controller
    $roles = Get-LabMachineRoleDefinition -Role RootDC
    #The PostInstallationActivity is just creating some users
    $postInstallActivity = @()
    $postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
    $postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
    Add-LabMachineDefinition -Name POSHDC1 -Memory 512MB -Roles RootDC -IpAddress $lab.Dns1 -PostInstallationActivity $postInstallActivity

    #the root domain gets a second domain controller
    Add-LabMachineDefinition -Name POSHDC2 -Memory 512MB -Roles DC -IpAddress $lab.Dns2

    #file server
    Add-LabMachineDefinition -Name POSHFS1 -Memory 512MB -Roles FileServer

    #web server
    Add-LabMachineDefinition -Name POSHWeb1 -Memory 512MB -Roles WebServer


    Install-Lab
}

Connect-Lab -SourceLab $labs.Get(0).LabName -DestinationLab $labs.Get(1).LabName