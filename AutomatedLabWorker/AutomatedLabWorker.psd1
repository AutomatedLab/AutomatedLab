@{
	# Script module or binary module file associated with this manifest
	RootModule = 'AutomatedLabWorker.psm1'
	
	# Version number of this module.
	ModuleVersion = '3.8.0.10'
	
	# ID used to uniquely identify this module
	GUID = '3addac35-cd7a-4bd2-82f5-ab9c83a48246'
	
	# Author of this module
	Author = 'Raimund Andree, Per Pedersen'
	
	# Company or vendor of this module
	CompanyName = 'AutomatedLab Team'
	
	# Copyright statement for this module
	Copyright = '2016'
	
	# Description of the functionality provided by this module
	Description = 'This module encapsulates all the work activities to prepare the lab'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '4.0'
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '4.0'
	
	# Modules to import as nested modules of the module specified in ModuleToProcess
	NestedModules = @('AutomatedLabWorkerInternals.psm1', 'AutomatedLabWorkerADCS.psm1', 'AutomatedLabWorkerDisks.psm1', 'AutomatedLabWorkerVirtualMachines.psm1', 'AutomatedLabWorkerNetwork.psm1', 'AutomatedLabAzureWorkerNetwork.psm1', 'AutomatedLabAzureWorkerVirtualMachines.psm1', 'AutomatedLabVMWareWorkerVirtualMachines.psm1', 'AutomatedLabVMWareWorkerNetwork.psm1')
	
	# List of all modules packaged with this module
	ModuleList = @('AutomatedLabWorker.psm1', 'AutomatedLabWorkerInternals.psm1', 'AutomatedLabWorkerADCS.psm1', 'AutomatedLabWorkerDisks.psm1', 'AutomatedLabWorkerVirtualMachines.psm1', 'AutomatedLabWorkerNetwork.psm1', 'AutomatedLabAzureWorkerNetwork.psm1', 'AutomatedLabAzureWorkerVirtualMachines.psm1', 'AutomatedLabVMWareWorkerVirtualMachines.psm1', 'AutomatedLabVMWareWorkerNetwork.psm1')
	
	# List of all files packaged with this module
	FileList = @('AutomatedLabWorker.psm1', 'AutomatedLabWorkerInternals.psm1', 'AutomatedLabWorkerADCS.psm1', 'AutomatedLabWorkerDisks.psm1', 'AutomatedLabWorkerVirtualMachines.psm1', 'AutomatedLabWorkerNetwork.psm1', 'AutomatedLabAzureWorkerNetwork.psm1', 'AutomatedLabAzureWorkerVirtualMachines.psm1', 'AutomatedLabVMWareWorkerVirtualMachines.psm1', 'AutomatedLabVMWareWorkerNetwork.psm1')

    # Private data to pass to the module specified in ModuleToProcess
	PrivateData = @{
		SupportGen2VMs = $true
	}
}