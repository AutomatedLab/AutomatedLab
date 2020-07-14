Creating your lab starts with New-LabDefinition. This cmdlet creates a container that holds all the lab items like networks and machines.

It is mandatory to define the name of the lab and the virtualization engine. So far AL supports Hyper-V and Azure.

``` powershell
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV -Path D:\AutomatedLabs -VmPath D:\AutomatedLab-VMs
```

- **New-LabDefinition** Parameters
  - **Name**: The name if the lab to create. The name must be unique.
  - **DefaultVirtualizationEngine**: HyperV for local deployments or Azure to deploy into the cloud.
  - **Path**: This is the path were the lab files will go (screenshot 1). If not defined the labs will be stored in "C:\Users\<username>\Documents\AutomatedLab-Labs".
  - **VmPath**: This is where AL creates the virtual machines. If this path is not defined AL will choose the fastest drive by trying not to use the system drive and create a folder there names "AutomatedLab-VMs".

During the lab deployment, AL exports your definitions into XML files. By default these are stored in 'C:\Users\<username>\Documents\AutomatedLab-Labs'. If you close the PowerShell session after the lab deployment, you can import the lab again using the Import-Lab cmdlet.

!https://cloud.githubusercontent.com/assets/11280760/20555110/6f12f9a8-b160-11e6-863a-bac119eac71b.png!

The virtual machines are stored in a different folder. AL tries to determine the fastest drive and uses the cmdlet Get-DiskSpeed for this. AL tries to avoid using the system drive. The speed test runs only once and results are cached. However if you plug in a new drive, AL takes it into consideration and measure its speed.

!https://cloud.githubusercontent.com/assets/11280760/20642671/252e839a-b415-11e6-8c80-307f7662d64a.JPG!

Starting with version 5.23, each lab deployment will not only be validated before the deployment but also
when the installation is finished. To enable the deployment validation, you need to install Pester 5.0.1+.
We did not mark Pester as a dependency, as these tests are optional.

## Lab building with the REST API

With the custom role 'LabBuilder' it is now possible to create a simple REST API powered by [Polaris](https://github.com/PowerShell/Polaris) on any virtualization host. The REST API provides the following functionality:

### Create

```powershell
$request = @{
    LabScript = Get-Content "$labsources\Sample Scripts\Introduction\01 Single Win10 Client.ps1" -Raw
} | ConvertTo-Json

# Queue new job, use GUID to request status update with GET method
$guid = Invoke-RestMethod -Method Post -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json
```

### Read

```powershell
# All labs (Get-Lab -List)
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Labs
# Specific lab
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Name=Win10
# Lab creation job (monitoring long running jobs)
Invoke-RestMethod -Method Get -Uri http://NestedBuilder/Lab?Id=5b89babb-7402-4a7a-9c16-86e1d52613fa
```

### Delete

```powershell
# As query parameter
Invoke-RestMethod -Method Delete -Uri http://NestedBuilder/Lab?Name=Win10

# Or as JSON body
$request = @{Name = 'Win10'} | ConvertTo-Json
Invoke-RestMethod -Method Delete -Uri http://NestedBuilder/Lab -Body $request -ContentType application/json
```

### Lab scenario including the builder

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