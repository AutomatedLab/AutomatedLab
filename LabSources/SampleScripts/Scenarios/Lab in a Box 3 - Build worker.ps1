<#
Build a lab with the help of nested virtualization. Adjust the machine memory if necessary.
The build worker will use Polaris as a simple REST endpoint that takes your lab data to deploy.

AutomatedLab will be copied to the machine. Lab sources will be mirrored to the machine as well, so that lab deployments can start immediately
#>
param
(
    [string]
    $LabName = 'LabAsAService',

    [ValidateSet('yes', 'no')]
    $TelemetryOptIn = 'no', # Opt out of telemetry for build worker by saying yes here

    [char]
    $LabSourcesDriveLetter = 'L'
)

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV
Add-LabVirtualNetworkDefinition -Name $labName -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

$role = Get-LabPostInstallationActivity -CustomRole LabBuilder -Properties @{TelemetryOptIn = $TelemetryOptIn; LabSourcesDrive = "$LabSourcesDriveLetter" }

$machineParameters = @{
    Name                     = 'NestedBuilder'
    PostInstallationActivity = $role
    OperatingSystem          = 'Windows Server 2016 Datacenter (Desktop Experience)'
    Memory                   = 16GB
    Network                  = $labName
    DiskName                 = 'vmDisk'
    Roles                    = 'HyperV' # optional, will be configured otherwise
}

$estimatedSize = [Math]::Round(((Get-ChildItem $labsources -File -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB + 20), 0)
$disk = Add-LabDiskDefinition -Name vmDisk -DiskSizeInGb $estimatedSize -PassThru -DriveLetter $LabSourcesDriveLetter

Add-LabMachineDefinition @machineParameters

Install-Lab

break

# REST-Methods to interact with

# List
$credential = (Get-LabVm -ComputerName NestedBuilder).GetCredential((Get-lab))
$allLabs = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab -Credential $credential

# throws, does not exist yet
$specificLab = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab/Win10 -Credential $credential

# throws, does not exist yet
$specificLab = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Name=Win10 -Credential $credential

# A lab installation job, if it exists
$labCreationJob = Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Job?Id=5b89babb-7402-4a7a-9c16-86e1d52613fa -Credential $credential

# Create lab
$request = @{
    LabScript = [string](Get-Content "$labsources\SampleScripts\Introduction\01 Single Win10 Client.ps1" -Raw) # cast to string -> Workaround if this is ever executed in PowerShell_ISE
} | ConvertTo-Json

$guid = Invoke-RestMethod -Method Post -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json -Credential $credential

# Get Status
$labCreationJob = Invoke-RestMethod -Method Get -Uri "http://NestedBuilder/Job/$($guid.Name)" -Credential $credential

# Retrieve lab properties
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab/Win10 -Credential $credential

# Remove lab
Invoke-RestMethod -Method Delete -Uri http://NestedBuilder/Lab/Win10 -Credential $credential
