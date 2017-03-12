@{
	RootModule = 'PSLog.psm1'
	
	ModuleVersion = '4.0.0.2'
	
	GUID = 'cd303a6c-f405-4dcb-b1ce-fbc2c52264e9'
	
	Author = 'Raimund Andree, Per Pedersen'

    Description = 'Redirects stanard Write-* cmdlets to a log and offers some basic tracing functions'
	
	CompanyName = 'AutomatedLab Team'
	
	Copyright = '2015'
	
	PowerShellVersion = '2.0'
	
	DotNetFrameworkVersion = '3.5'
	
	ModuleList = @('PSLog')
	
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