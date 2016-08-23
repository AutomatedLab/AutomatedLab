@{
	# Script module or binary module file associated with this manifest
	ModuleToProcess = 'HostsFile.psm1'
	
	# Version number of this module.
	ModuleVersion = '3.5'
	
	# ID used to uniquely identify this module
	GUID = '8dc3dd5c-5ae8-4198-a8f2-2157ab6b725c'
	
	# Author of this module
	Author = 'Raimund Andree, Per Pedersen'
	
	# Company or vendor of this module
	CompanyName = 'AutomatedLab Team'
	
	# Copyright statement for this module
	Copyright = '2015'
	
	# Description of the functionality provided by this module
	Description = 'This module provides management of hosts file content'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '3.0'
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '4.0'

	# Functions to export from this module
	FunctionsToExport = 'Add-HostEntry', 'Clear-HostFile', 'Get-HostEntry', 'Open-HostFile', 'Remove-HostEntry', 'Save-HostFile'
	
	# List of all modules packaged with this module
	ModuleList = @('HostsFile.psm1')
	
	# List of all files packaged with this module
	FileList = @('HostsFile.psm1', 'HostsFile.psd1')
}