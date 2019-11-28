function Update-LabVMWareSettings
{
	if ((Get-PSCallStack).Command -contains 'Import-Lab')
	{
		$Script:lab = Get-Lab
	}
	elseif ((Get-PSCallStack).Command -contains 'Add-LabVMWareSettings')
	{
		$Script:lab = Get-LabDefinition
	}
}

function Add-LabVMWareSettings
{
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

    Update-LabVMWareSettings

    #loading a snaping twice results in: Add-PSSnapin : An item with the same key has already been added
	#Add-PSSnapin -Name VMware.VimAutomation.Core, VMware.VimAutomation.Vds -ErrorAction Stop

	if (-not $script:lab.VMWareSettings)
	{
		$script:lab.VMWareSettings = New-Object AutomatedLab.VMWareConfiguration
	}

	Connect-VIServer -Server $VCenterServerName -Credential $Credential -ErrorAction Stop

    $script:lab.VMWareSettings.DataCenter = Get-Datacenter -Name $DataCenterName -ErrorAction Stop
    $Script:lab.VMWareSettings.DataCenterName = $DataCenterName

    $script:lab.VMWareSettings.DataStore = Get-Datastore -Name $DataStoreName -ErrorAction SilentlyContinue
    $script:lab.VMWareSettings.DataStoreName = $DataStoreName
    if (-not $script:lab.VMWareSettings.DataStore)
    {
        $script:lab.VMWareSettings.DataStore = Get-DatastoreCluster -Name $DataStoreName -ErrorAction SilentlyContinue
    }
    if (-not $script:lab.VMWareSettings.DataStore)
    {
        throw "Could not find a DataStore nor a DataStoreCluster with the name '$DataStoreName'"
    }

    $script:lab.VMWareSettings.ResourcePool = Get-ResourcePool -Name $ResourcePoolName -Location $script:lab.VMWareSettings.DataCenter -ErrorAction Stop
    $script:lab.VMWareSettings.ResourcePoolName = $ResourcePoolName

    $script:lab.VMWareSettings.VCenterServerName = $VCenterServerName
    $script:lab.VMWareSettings.Credential = [System.Management.Automation.PSSerializer]::Serialize($Credential)

	if ($PassThru)
	{
		$script:lab.VMWareSettings
	}

	Write-LogFunctionExit
}