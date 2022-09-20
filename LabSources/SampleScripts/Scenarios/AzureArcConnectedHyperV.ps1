<#
.SYNOPSIS
    Deploy Hyper-V lab and connect VMs to Azure
.DESCRIPTION
    Deploys a Hyper-V lab with Domain Services, Certificate Services, SQL Server and web servers
    and connects VMs using Azure Arc.
    Prerequisites:
      - Ensure that the HybridCompute provider is registered: Get-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute | Where RegistrationState -eq Registered
      - If it is not registered, ensure you have the permissions to register it
      - Internet connectivity
.EXAMPLE
    ./AzureArcConnectedHyperV.ps1 -SubscriptionName arcsub
#>
param
(
    [Parameter(ParameterSetName = 'SubId')]
    [Parameter(ParameterSetName = 'SubName')]
    [string]
    $LabName = 'HyperVWithArc',

    [Parameter(ParameterSetName = 'SubId', Mandatory = $true)]
    [guid]
    $SubscriptionId,

    [Parameter(ParameterSetName = 'SubName', Mandatory = $true)]
    [string]
    $SubscriptionName,

    [Parameter(ParameterSetName = 'SubId')]
    [Parameter(ParameterSetName = 'SubName')]
    [string]
    $ArcResourceGroupName = 'ALArc',

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

if (-not (Get-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute | Where RegistrationState -eq Registered))
{
    $status = Register-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute
    while ($status.RegistrationState -contains 'Registering')
    {
        Start-Sleep -Seconds 10
        $status = Get-AzResourceProvider -ProviderNamespace Microsoft.HybridCompute
    }
}

New-LabDefinition -Name $LabName -DefaultVirtualizationEngine HyperV

$sqlIso = (Get-ChildItem -Path "$Labsources/ISOs" -Filter *SQL*2019* | Select-Object -First 1).FullName
if (-not $sqlIso)
{
    $sqlIso = Read-Host -Prompt 'Please enter the full path to your SQL Server 2019 ISO'
}

if (-not (Test-Path $sqlIso)) { throw "SQL ISO $sqlIso not found." }

Add-LabIsoImageDefinition -Name SQLServer2019 -Path $sqlIso

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2022 Datacenter'
    'Add-LabMachineDefinition:Memory' = 2GB
}

Add-LabMachineDefinition -Name ARCDC01 -Role RootDC
Add-LabMachineDefinition -Name ARCCA01 -Role CARoot
Add-LabMachineDefinition -Name ARCDB01 -OperatingSystem 'Windows Server 2022 Datacenter (Desktop Experience)' -Role SQLServer2019
Add-LabMachineDefinition -Name ARCWB01 -Role WebServer
Add-LabMachineDefinition -Name ARCWB02 -Role WebServer

Install-Lab

Save-Module -Name Az.ConnectedMachine -Repository PSGallery -Path "$labSources/Tools" -Force
Import-Module -Name "$labSources/Tools/Az.ConnectedMachine"
$sessions = New-LabPSSession -ComputerName (Get-LabVm)
Invoke-LabCommand -ComputerName (Get-LabVm) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 } # Yes, really...
Connect-AzConnectedMachine -ResourceGroupName $ArcResourceGroupName -PSSession $sessions -Location $Location