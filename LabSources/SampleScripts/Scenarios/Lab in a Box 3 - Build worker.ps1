<#
Build a lab with the help of nested virtualization. Adjust the machine memory if necessary.
The build worker will use Polaris as a simple REST endpoint that takes your lab data to deploy.

AutomatedLab will be copied to the machine. If specified, the lab sources can be mirrored
to the VM. If so, an additional disk will be created.
#>
param
(
    [string]
    $labName = 'LabAsAService'
)

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV
Add-LabVirtualNetworkDefinition -Name $labName -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

$role = Get-LabPostInstallationActivity -CustomRole LabBuilder
$machineParameters = @{
    Name                     = 'NestedBuilder'
    PostInstallationActivity = $role
    OperatingSystem          = 'Windows Server 2016 Datacenter (Desktop Experience)'
    Memory                   = 16GB
    Network                  = $labName
    DiskName                 = 'vmDisk'
}


$estimatedSize = [Math]::Round(((Get-ChildItem $labsources -File -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB + 20), 0)
$disk = Add-LabDiskDefinition -Name vmDisk -DiskSizeInGb $estimatedSize -PassThru

Add-LabMachineDefinition @machineParameters

Install-Lab
