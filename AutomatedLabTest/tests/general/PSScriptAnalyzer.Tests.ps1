[CmdletBinding()]
Param (
	[switch]
	$SkipTest,
	
	[string[]]
	$CommandPath = @("$PSScriptRoot\..\..\functions", "$PSScriptRoot\..\..\internal\functions")
)

if ($SkipTest) { return }

$list = New-Object System.Collections.ArrayList

Describe 'Invoking PSScriptAnalyzer against commandbase' {
	$commandFiles = Get-ChildItem -Path $CommandPath -Recurse | Where-Object Name -like "*.ps1"
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
						$analysis | Where-Object RuleName -EQ $rule -outvariable failures | ForEach-Object { $list.Add($_) }
						
						1 | Should Be 0
					}
					else
					{
						0 | Should Be 0
					}
				}
			}
		}
	}
}

$list | Out-Default