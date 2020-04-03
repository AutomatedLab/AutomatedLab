[CmdletBinding()]
param
(
    [string]
    $DomainName = 'contoso.com',

    [Parameter(Mandatory)]
    [pscredential]
    $DomainJoinCredential,

    # The name of the adapter that can be used for the external VSwitch
    [string]
    $ExternalAdapterName = 'Ethernet'
)

New-LabDefinition -Name ExDomLab -DefaultVirtualizationEngine HyperV

Write-ScreenInfo -Message "Locating writeable domain controller for $DomainName"
$ctx = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Domain', $DomainName)
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($ctx)
$dc = $domain.FindDomainController([System.DirectoryServices.ActiveDirectory.LocatorOptions]::WriteableRequired).Name
$dcName = $dc.Replace(".$DomainName", '')
$dcIp = [System.Net.Dns]::GetHostAddresses($dc).IpAddressToString
if ($null -eq $dc)
{
    Write-ScreenInfo -Type Error -Message "Unable to detect writeable DC for $DomainName - cannot continue."
    return
}

Write-ScreenInfo -Message "Discovered writeable DC $dc - Joining all Lab VMs to it"

Set-LabInstallationCredential -Username ($DomainJoinCredential.UserName -split '\\')[-1] -Password $DomainJoinCredential.GetNetworkCredential().Password
# We are not using a domain admin as we skip the deployment of the DC. Nevertheless, this credential is used for domain joins.
Add-LabDomainDefinition -Name $DomainName -AdminUser ($DomainJoinCredential.UserName -split '\\')[-1] -AdminPassword $DomainJoinCredential.GetNetworkCredential().Password

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = $DomainName
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server Datacenter'
    'Add-LabMachineDefinition:Memory' = 4GB
    'Add-LabMachineDefinition:Network' = "Network$DomainName"
}

Add-LabVirtualNetworkDefinition -Name "Network$DomainName" -HyperVProperties @{AdapterName = $ExternalAdapterName; SwitchType = 'External'}
Add-LabMachineDefinition -Name $dcName -Roles RootDc -SkipDeployment -IpAddress $dcIp
Add-LabMachineDefinition -Name POSHFS01
Add-LabMachineDefinition -Name POSHWEB01

Install-Lab