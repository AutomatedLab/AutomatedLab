param (
	$TestGeneral = $true,
	
	$TestFunctions = $true,
	
	[ValidateSet('None', 'Default', 'Passed', 'Failed', 'Pending', 'Skipped', 'Inconclusive', 'Describe', 'Context', 'Summary', 'Header', 'Fails', 'All')]
	$Show = "None",
	
	$Include = "*",
	
	$Exclude = ""
)

Write-PSFMessage -Level Important -Message "Starting Tests"

Write-PSFMessage -Level Important -Message "Importing Module"

Remove-Module AutomatedLabTest -ErrorAction Ignore
Import-Module "$PSScriptRoot\..\AutomatedLabTest.psd1"
Import-Module "$PSScriptRoot\..\AutomatedLabTest.psm1" -Force



$totalFailed = 0
$totalRun = 0

$testresults = @()

#region Run General Tests
if ($TestGeneral)
{
	Write-PSFMessage -Level Important -Message "Modules imported, proceeding with general tests"
	foreach ($file in (Get-ChildItem "$PSScriptRoot\general" | Where-Object Name -like "*.Tests.ps1"))
	{
		Write-PSFMessage -Level Significant -Message "  Executing <c='em'>$($file.Name)</c>"
		$results = Invoke-Pester -Path $file.FullName -Output $Show -PassThru
		$totalRun += $results.TotalCount
		$totalFailed += $results.FailedCount
		foreach ($result in $results.Failed)
		{
			$testresults += [pscustomobject]@{
				Describe = $result.Block.Path[1]
				Context  = $result.Block.Path[0]
				Name	 = $result.Block.Name
				Result   = $result.Result
				Message  = $result.ErrorRecord.Exception.Message
			}
		}
	}
}
#endregion Run General Tests

#region Test Commands
if ($TestFunctions)
{
Write-PSFMessage -Level Important -Message "Proceeding with individual tests"
	foreach ($file in (Get-ChildItem "$PSScriptRoot\functions" -Recurse -File | Where-Object Name -like "*Tests.ps1"))
	{
		if ($file.Name -notlike $Include) { continue }
		if ($file.Name -like $Exclude) { continue }
		
		Write-PSFMessage -Level Significant -Message "  Executing $($file.Name)"
		$results = Invoke-Pester -Path $file.FullName -Output $Show -PassThru
		$totalRun += $results.TotalCount
		$totalFailed += $results.FailedCount
		foreach ($result in $results.Failed)
		{
			$testresults += [pscustomobject]@{
				Describe = $result.Block.Path[1]
				Context  = $result.Block.Path[0]
				Name	 = $result.Block.Name
				Result   = $result.Result
				Message  = $result.ErrorRecord.Exception.Message
			}
		}
	}
}
#endregion Test Commands

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

if ($totalFailed -eq 0) { Write-PSFMessage -Level Critical -Message "All <c='em'>$totalRun</c> tests executed without a single failure!" }
else { Write-PSFMessage -Level Critical -Message "<c='em'>$totalFailed tests</c> out of <c='sub'>$totalRun</c> tests failed!" }

if ($totalFailed -gt 0)
{
	throw "$totalFailed / $totalRun tests failed!"
}