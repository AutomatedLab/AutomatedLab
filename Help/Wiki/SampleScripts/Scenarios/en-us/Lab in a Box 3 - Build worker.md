# Scenarios - Lab in a Box 3 - Build worker

INSERT TEXT HERE

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

break

# REST-Methods to interact with

# List
$allLabs = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Labs
$specificLab = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Name=Win10 # throws, does not exist yet
$labCreationJob = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Id=5b89babb-7402-4a7a-9c16-86e1d52613fa # A lab installation job, if it exists

# Create lab
$request = @{
    LabScript = Get-Content "$labsources\Sample Scripts\Introduction\01 Single Win10 Client.ps1" -Raw
} | ConvertTo-Json

$guid = Invoke-RestMethod -Method Post -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json

# Get Status
$labCreationJob = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Id=$guid

# Remove lab
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Name=Win10 # Retrieve lab properties

$request = @{Name = 'Win10'} | ConvertTo-Json
Invoke-RestMethod -Method Delete -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json

```
