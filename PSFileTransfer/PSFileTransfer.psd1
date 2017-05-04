@{
	RootModule = 'PSFileTransfer.psm1'
	
	ModuleVersion = '4.0.0.0'
	
	GUID = '789c9c76-4756-4489-a74f-31ca64488c7b'
	
	Author = 'Raimund Andree, Per Pedersen'
	
	CompanyName = 'AutomatedLab Team'
	
	Copyright = '2015'
	
	Description = 'This module packages functions created by Lee Holmes for transfering files over PowerShell Remoting'
	
	PowerShellVersion = '3.0'
	
	DotNetFrameworkVersion = '2.0'

	ModuleList = @('PSFileTransfer')
	
	FunctionsToExport = 'Copy-LabFileItem', 'Send-Directory', 'Send-File', 'Receive-Directory', 'Receive-File'
	
	FileList = @('PSFileTransfer.psm1', 'PSFileTransfer.psd1')
}