[CmdletBinding()]
Param (
	[switch]
	$SkipTest,
	
	[string[]]
	$CommandPath 
)

if ($SkipTest) { return }

$global:list = New-Object System.Collections.ArrayList

Describe 'Invoking PSScriptAnalyzer against commandbase' {
	$commandFiles = Get-ChildItem -Path @("$PSScriptRoot\..\..\functions", "$PSScriptRoot\..\..\internal\functions") -Recurse | Where-Object Name -like "*.ps1"
	$scriptAnalyzerRules = Get-ScriptAnalyzerRule
	
	foreach ($file in $commandFiles)
	{
		Context "Analyzing $($file.BaseName)" {
			$analysis = Invoke-ScriptAnalyzer -Path $file.FullName -ExcludeRule PSAvoidTrailingWhitespace, PSShouldProcess
			
			forEach ($rule in $scriptAnalyzerRules)
			{
				It "Should pass $rule" {
					If ($analysis.RuleName -contains $rule)
					{
						$analysis | Where-Object RuleName -EQ $rule -outvariable failures | ForEach-Object { $global:list.Add($_) }
						
						1 | Should -Be 0
					}
					else
					{
						0 | Should -Be 0
					}
				}
			}
		}
	}
}

$global:list | Out-Default