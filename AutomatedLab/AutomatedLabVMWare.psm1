function Update-LabVMwareSettings
{
    # .ExternalHelp AutomatedLab.Help.xml
    if ((Get-PSCallStack).Command -contains 'Import-Lab')
    {
        $Script:lab = Get-Lab
    }
    elseif ((Get-PSCallStack).Command -contains 'Add-LabVMwareSettings')
    {
        $Script:lab = Get-LabDefinition
    }
}

function Add-LabVMwareSettings
{
    # .ExternalHelp AutomatedLab.Help.xml
    param (
        [Parameter(Mandatory)]
        [string]$DataCenterName,

        [Parameter(Mandatory)]
        [string]$DataStoreName,

        [Parameter(Mandatory)]
        [string]$ResourcePoolName,

        [Parameter(Mandatory)]
        [string]$VCenterServerName,

        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    Update-LabVMwareSettings

    # loading a snapin twice results in: Add-PSSnapin : An item with the same key has already been added
    # Add-PSSnapin -Name VMware.VimAutomation.Core, VMware.VimAutomation.Vds -ErrorAction Stop

    if (-not $script:lab.VMwareSettings)
    {
        $script:lab.VMwareSettings = New-Object AutomatedLab.VMwareConfiguration
    }

    Connect-VIServer -Server $VCenterServerName -Credential $Credential -ErrorAction Stop

    $script:lab.VMwareSettings.DataCenter = Get-Datacenter -Name $DataCenterName -ErrorAction Stop
    $Script:lab.VMwareSettings.DataCenterName = $DataCenterName

    $script:lab.VMwareSettings.DataStore = Get-Datastore -Name $DataStoreName -ErrorAction SilentlyContinue
    $script:lab.VMwareSettings.DataStoreName = $DataStoreName
    if (-not $script:lab.VMwareSettings.DataStore)
    {
        $script:lab.VMwareSettings.DataStore = Get-DatastoreCluster -Name $DataStoreName -ErrorAction SilentlyContinue
    }
    if (-not $script:lab.VMwareSettings.DataStore)
    {
        throw "Could not find a DataStore nor a DataStoreCluster with the name '$DataStoreName'"
    }

    $script:lab.VMwareSettings.ResourcePool = Get-ResourcePool -Name $ResourcePoolName -Location $script:lab.VMwareSettings.DataCenter -ErrorAction Stop
    $script:lab.VMwareSettings.ResourcePoolName = $ResourcePoolName

    $script:lab.VMwareSettings.VCenterServerName = $VCenterServerName
    $script:lab.VMwareSettings.Credential = [System.Management.Automation.PSSerializer]::Serialize($Credential)

    if ($PassThru)
    {
        $script:lab.VMwareSettings
    }

    Write-LogFunctionExit
}