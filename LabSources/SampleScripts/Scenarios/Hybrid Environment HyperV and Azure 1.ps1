<#
This lab script serves the purpose of showing you how to create and connect an on-premises to an Azure lab.

You will need an Azure subscription.
#>

# Define your labs. Make sure that the virtual network address spaces do not overlap.
$labs = @(
    @{
        LabName = 'SourceNameHere'
        AddressSpace = '192.168.50.0/24'
        Domain = 'powershell.isawesome'
        Dns1 = '192.168.50.10'
        Dns2 ='192.168.50.11'
        OnAzure = $false
        Location = 'West Europe'
    }
    @{
        LabName = 'DestinationNameHere'
        AddressSpace = '192.168.100.0/24'
        Domain = 'powershell.power'
        Dns1 = '192.168.100.10'
        Dns2 ='192.168.100.11'
        Location = 'East US'
        OnAzure = $true
    }
)

foreach ($lab in $labs.GetEnumerator())
{
    $engine = if ($lab.OnAzure) { "Azure" } else { "HyperV" }
    New-LabDefinition -Name $lab.LabName -DefaultVirtualizationEngine $engine

    if($lab.OnAzure)
    {
        Add-LabAzureSubscription -DefaultLocationName $lab.Location
    }

    #make the network definition
    Add-LabVirtualNetworkDefinition -Name $lab.LabName -AddressSpace $lab.AddressSpace
    if (-not $lab.OnAzure)
    {
        Add-LabVirtualNetworkDefinition -Name ExternalDHCP -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }
    }

    #and the domain definition with the domain admin account
    Add-LabDomainDefinition -Name $lab.Domain -AdminUser Install -AdminPassword Somepass1

    Set-LabInstallationCredential -Username Install -Password Somepass1

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

    #router
    if (-not $lab.OnAzure)
    {
        $netAdapter = @()
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $lab.LabName
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch ExternalDHCP -UseDhcp
        Add-LabMachineDefinition -Name POSHGW1 -Memory 512MB -Roles Routing -NetworkAdapter $netAdapter
    }


    Install-Lab
}

Connect-Lab -SourceLab $labs.Get(0).LabName -DestinationLab $labs.Get(1).LabName

Import-Lab $labs.Get(0).LabName -NoValidation

Invoke-LabCommand POSHDC1 -ScriptBlock {
    param
    (
        $connectedLabMachine
    )

    if(Test-Connection $connectedLabMachine -ErrorAction SilentlyContinue)
    {
        Write-Host "Connection established"
    }
    else
    {
        Write-ScreenInfo "Could not connect to $connectedLabMachine" -Type Warning
    }
} -ArgumentList "POSHDC1.$($labs.Get(1).Domain)" -PassThru
