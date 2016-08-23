@{
	# Script module or binary module file associated with this manifest
	ModuleToProcess = 'PSLog.psm1'
	
	# Version number of this module.
	ModuleVersion = '3.5'
	
	# ID used to uniquely identify this module
	GUID = 'cd303a6c-f405-4dcb-b1ce-fbc2c52264e9'
	
	# Author of this module
	Author = 'Raimund Andree, Per Pedersen'
	
	# Company or vendor of this module
	CompanyName = 'AutomatedLab Team'
	
	# Copyright statement for this module
	Copyright = '2015'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '2.0'
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '3.5'
	
	# List of all modules packaged with this module
	ModuleList = @('PSLog.psm1')
	
	# Private data to pass to the module specified in ModuleToProcess
	PrivateData = @{
		AutoStart = $true
		DefaultFolder = $null
		DefaultName = 'PSLog'
		Level = 'All'
		Silent = $false
		TruncateTypes = @(
		    'System.Management.Automation.ScriptBlock'
		)
		TruncateLength = 50
	}
}