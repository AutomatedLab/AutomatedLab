# Lab building with the REST API

With the custom role 'LabBuilder' it is now possible to create a simple REST API powered by [Polaris](https://github.com/PowerShell/Polaris) on any virtualization host. The REST API provides the following functionality:

## Create

```powershell
$request = @{
    LabScript = Get-Content "$labsources\Sample Scripts\Introduction\01 Single Win10 Client.ps1" -Raw
} | ConvertTo-Json

# Queue new job, use GUID to request status update with GET method
$guid = Invoke-RestMethod -Method Post -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json
```

## Read

```powershell
# All labs (Get-Lab -List)
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Labs
# Specific lab
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Name=Win10
# Lab creation job (monitoring long running jobs)
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Id=5b89babb-7402-4a7a-9c16-86e1d52613fa
```

## Delete

```powershell
# As query parameter
Invoke-RestMethod -Method Delete -Uri http://NestedBuilder/Lab?Name=Win10

# Or as JSON body
$request = @{Name = 'Win10'} | ConvertTo-Json
Invoke-RestMethod -Method Delete -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json
```

## Lab scenario including the builder

The following lab scenario configures a simple VM to test-drive this feature. Be aware that when using this on Azure your lab sources need to be uploaded first. Otherwise you will need to manually copy all necessary ISO files to your Azure VM.

```powershell
<#
Build a lab with the help of nested virtualization. Adjust the machine memory if necessary.
The build worker will use Polaris as a simple REST endpoint that takes your lab data to deploy.

AutomatedLab will be copied to the machine. Lab sources will be mirrored to the machine as well, so that lab deployments can start immediately
#>
param
(
    [string]
    $LabName = 'LabAsAService',

    [ValidateSet('yes','no')]
    $TelemetryOptOut = 'no' # Opt out of telemetry for build worker by saying yes here
)

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV
Add-LabVirtualNetworkDefinition -Name $labName -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

$role = Get-LabPostInstallationActivity -CustomRole LabBuilder -Properties @{TelemetryOptOut = $TelemetryOptOut}

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
```