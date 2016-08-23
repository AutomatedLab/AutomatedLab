@{
	# Script module or binary module file associated with this manifest
	ModuleToProcess = 'PSFileTransfer.psm1'
	
	# Version number of this module.
	ModuleVersion = '3.5'
	
	# ID used to uniquely identify this module
	GUID = '789c9c76-4756-4489-a74f-31ca64488c7b'
	
	# Author of this module
	Author = 'Raimund Andree, Per Pedersen'
	
	# Company or vendor of this module
	CompanyName = 'AutomatedLab Team'
	
	# Copyright statement for this module
	Copyright = '2015'
	
	# Description of the functionality provided by this module
	Description = 'This module packages functions created by Lee Holmes for transfering files over PowerShell Remoting'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = '3.0'
	
	# Minimum version of the .NET Framework required by this module
	DotNetFrameworkVersion = '2.0'
	
	# Functions to export from this module
	FunctionsToExport = 'Copy-LabFileItem', 'Send-Directory', 'Send-File', 'Receive-Directory', 'Receive-File'
	
	# List of all modules packaged with this module
	ModuleList = @('PSFileTransfer.psm1')
	
	# List of all files packaged with this module
	FileList = @('PSFileTransfer.psm1', 'PSFileTransfer.psd1')
}