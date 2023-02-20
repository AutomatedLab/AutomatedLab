# Scenarios - HybridHyperVAzureArc

Hybrid lab deployment on Hyper-V and Azure, all VMs are connected
to Azure Arc.

```powershell
<#
.SYNOPSIS
    Deploy one Hyper-V and one Azure lab, connect labs, onboard VMs to Arc
.DESCRIPTION
    Deploys one Hyper-V and one Azure lab with
    - Domain Services
    - Web server
    - File Server

    and connects VMs using Azure Arc.
    Prerequisites:
      - Ensure that the HybridCompute provider is registered: Get-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute | Where RegistrationState -eq Registered
      - If it is not registered, ensure you have the permissions to register it
      - Internet connectivity
      - An Azure subscription.

    Once the connection is complete and working via VPN, you can configure Private Enpoints and
    use Private link to access resources on Azure, use Bastion for your on-premises machines,
    apply Automanage Machine Configurations - the possibilities are endless.
.EXAMPLE
    ./HybridHyperVAzureArc.ps1.ps1 -SubscriptionName arcsub
#>
[CmdletBinding(DefaultParameterSetName = 'SubName')]
param
(
    # Name of the lab
    [Parameter(ParameterSetName = 'SubId')]
    [Parameter(ParameterSetName = 'SubName')]
    [string]
    $LabName = 'HyperVWithArc',

    # GUID of the subscription to be used
    [Parameter(ParameterSetName = 'SubId', Mandatory = $true)]
    [guid]
    $SubscriptionId,

    # Name of the subscription to be used
    [Parameter(ParameterSetName = 'SubName', Mandatory = $true)]
    [string]
    $SubscriptionName,

    # Name of the resource group Arc enabled machines should be placed in
    [Parameter(ParameterSetName = 'SubId')]
    [Parameter(ParameterSetName = 'SubName')]
    [string]
    $ArcResourceGroupName = 'ALArc',

    # Location of both the Arc resource group as well as the Arc enabled machines
    [Parameter(ParameterSetName = 'SubId')]
    [Parameter(ParameterSetName = 'SubName')]
    [string]
    $Location = 'westeurope'
)

if (-not (Get-AzSubscription -ErrorAction SilentlyContinue))
{
    $null = Connect-AzAccount -UseDeviceAuthentication
}

if ($SubscriptionId)
{
    $null = Set-AzContext -SubscriptionId $SubscriptionId.Guid

}
else
{
    $null = Set-AzContext -Subscription $SubscriptionName
}

if (-not (Get-AzLocation).Where({ $_.Location -eq $Location -or $_.DisplayName -eq $Location })) { throw "No Azure location found called $Location" }

if (-not (Get-AzResourceGroup -Name $ArcResourceGroupName -ErrorAction SilentlyContinue))
{
    $null = New-AzResourceGroup -ResourceGroupName $ArcResourceGroupName -Location $Location
}

$unregisteredProviders = (Get-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute, Microsoft.AzureArcData | Where RegistrationState -eq NotRegistered).ProviderNamespace | Select-Object -Unique
foreach ($provider in $unregisteredProviders)
{
    $null = Register-AzResourceProvider -ProviderNamespace $provider
}

$status = Get-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute, Microsoft.AzureArcData
while ($status.RegistrationState -contains 'Registering')
{
    Start-Sleep -Seconds 10
    $status = Get-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute, Microsoft.AzureArcData
}

$labs = @(
    @{
        LabName      = $LabName
        AddressSpace = '192.168.50.0/24'
        Domain       = 'powershell.isawesome'
        Dns1         = '192.168.50.10'
        Dns2         = '192.168.50.11'
        OnAzure      = $false
        Location     = 'West Europe'
    }
    @{
        LabName      = "az$LabName"
        AddressSpace = '192.168.100.0/24'
        Domain       = 'powershell.power'
        Dns1         = '192.168.100.10'
        Dns2         = '192.168.100.11'
        Location     = 'East US'
        OnAzure      = $true
    }
)

foreach ($lab in $labs)
{
    $engine, $prefix = if ($lab.OnAzure) { "Azure", 'az' } else { "HyperV", 'hv' }
    New-LabDefinition -Name $lab.LabName -DefaultVirtualizationEngine $engine

    if ($lab.OnAzure)
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
        'Add-LabMachineDefinition:Network'         = $lab.LabName
        'Add-LabMachineDefinition:ToolsPath'       = "$labSources\Tools"
        'Add-LabMachineDefinition:DomainName'      = $lab.Domain
        'Add-LabMachineDefinition:DnsServer1'      = $lab.Dns1
        'Add-LabMachineDefinition:DnsServer2'      = $lab.Dns2
        'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2022 Datacenter (Desktop Experience)'
    }

    #the first machine is the root domain controller
    $roles = Get-LabMachineRoleDefinition -Role RootDC
    #The PostInstallationActivity is just creating some users
    $postInstallActivity = @()
    $postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
    $postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
    Add-LabMachineDefinition -Name "$($prefix)POSHDC1" -Memory 512MB -Roles RootDC -IpAddress $lab.Dns1 -PostInstallationActivity $postInstallActivity

    #the root domain gets a second domain controller
    Add-LabMachineDefinition -Name "$($prefix)POSHDC2" -Memory 512MB -Roles DC -IpAddress $lab.Dns2 -DnsServer1 $lab.Dns2 -DnsServer2 $lab.Dns1

    #file server
    Add-LabMachineDefinition -Name "$($prefix)POSHFS1" -Memory 512MB -Roles FileServer

    #web server
    Add-LabMachineDefinition -Name "$($prefix)POSHWeb1" -Memory 512MB -Roles WebServer

    #router
    if (-not $lab.OnAzure)
    {
        $netAdapter = @()
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $lab.LabName
        $netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch ExternalDHCP -UseDhcp
        Add-LabMachineDefinition -Name "$($prefix)POSHGW1" -Memory 512MB -Roles Routing -NetworkAdapter $netAdapter
    }

    Install-Lab

    if ($lab.OnAzure) { continue }

    if (-not (Get-Module -ListAvailable -Name Az.ConnectedMachine))
    {
        Install-Module -Name Az.ConnectedMachine -Repository PSGallery -Force
    }

    $sessions = New-LabPSSession -ComputerName (Get-LabVm)
    Invoke-LabCommand -ComputerName (Get-LabVm) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 } -NoDisplay # Yes, really...
    Write-ScreenInfo -Message "Onboarding $((Get-LabVm).Name -join ',')" -Type Info
    foreach ($session in $sessions)
    {
        # Connect-AzConnectedMachine has a severe bug if more than one session is passed. Machines are onboarded, but errors are thrown.
        $null = Connect-AzConnectedMachine -ResourceGroupName $ArcResourceGroupName -PSSession $session -Location $Location
    }
}

Connect-Lab -SourceLab $labs[0].LabName -DestinationLab $labs[1].LabName

Import-Lab $labs[0].LabName -NoValidation

Invoke-LabCommand hvPOSHDC1 -ScriptBlock {
    param
    (
        $connectedLabMachine
    )

    if (Test-Connection $connectedLabMachine -ErrorAction SilentlyContinue)
    {
        Write-Host "Connection established"
    }
    else
    {
        Write-ScreenInfo "Could not connect to $connectedLabMachine" -Type Warning
    }
} -ArgumentList "hvPOSHDC1.$($labs[1].Domain)" -PassThru

```
