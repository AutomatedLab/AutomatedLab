@{
	RootModule = 'AutomatedLabTest.psm1'
	
	ModuleVersion = '4.5.0.0'
	
	GUID = '16580260-aab3-4f4c-a7ca-75cd310e4f0b'
	
	Author = 'Raimund Andree, Per Pedersen'
	
	CompanyName = 'AutomatedLab Team'
	
	Copyright = '2016'
	
	Description = 'The module is for testing AutomatedLab'
	
	PowerShellVersion = '4.0'
	
    DotNetFrameworkVersion = '4.0'
	
	CLRVersion = '4.0'
	
	FormatsToProcess = @('AutomatedLabTest.format.ps1xml')
	
	FunctionsToExport = @('Test-LabDeployment', 'Import-LabTestResult')
	
	ModuleList = @('AutomatedLabTest')
	
	FileList = @('AutomatedLabTest.format.ps1xml', 'AutomatedLabTest.psm1', 'AutomatedLabTest.psd1')
	
	PrivateData = @{}
}


