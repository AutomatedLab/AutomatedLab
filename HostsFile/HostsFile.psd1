@{
	RootModule = 'HostsFile.psm1'
	
	ModuleVersion = '3.5'
	
	GUID = '8dc3dd5c-5ae8-4198-a8f2-2157ab6b725c'
	
	Author = 'Raimund Andree, Per Pedersen'
	
	CompanyName = 'AutomatedLab Team'
	
	Copyright = '2015'
	
	Description = 'This module provides management of hosts file content'
	
	PowerShellVersion = '3.0'
	
	DotNetFrameworkVersion = '4.0'

	ModuleList = @('HostsFile')

	FunctionsToExport = 'Add-HostEntry', 'Clear-HostFile', 'Get-HostEntry', 'Open-HostFile', 'Remove-HostEntry', 'Save-HostFile'
	
	FileList = @('HostsFile.psm1', 'HostsFile.psd1')
}