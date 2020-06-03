Describe "Validating the module manifest" {
	Context "Basic resources validation" {		
		It "Exports all functions in the public folder" {
			$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
			$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
			$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
			
			$functions = (Compare-Object -ReferenceObject $files.BaseName -DifferenceObject $manifest.FunctionsToExport | Where-Object SideIndicator -Like '<=').InputObject
			$functions | Should -BeNullOrEmpty
		}
		It "Exports no function that isn't also present in the public folder" {
			$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
			$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
			$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
			$functions = (Compare-Object -ReferenceObject $files.BaseName -DifferenceObject $manifest.FunctionsToExport | Where-Object SideIndicator -Like '=>').InputObject
			$functions | Should -BeNullOrEmpty
		}
		
		It "Exports none of its internal functions" {
			$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
			$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
			$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
			$files = Get-ChildItem "$moduleRoot\internal\functions" -Recurse -File -Filter "*.ps1"
			$files | Where-Object BaseName -In $manifest.FunctionsToExport | Should -BeNullOrEmpty
		}
	}
	
	Context "Individual file validation" {
		It "The root module file exists" {
			$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
			$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
			$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
			Test-Path "$moduleRoot\$($manifest.RootModule)" | Should -Be $true
		}
		
		foreach ($format in $manifest.FormatsToProcess)
		{
			It "The file $format should exist" {
				$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
				$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
				$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
				Test-Path "$moduleRoot\$format" | Should -Be $true
			}
		}
		
		foreach ($type in $manifest.TypesToProcess)
		{
			It "The file $type should exist" {
				$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
				$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
				$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
				Test-Path "$moduleRoot\$type" | Should -Be $true
			}
		}
		
		foreach ($assembly in $manifest.RequiredAssemblies)
		{
            if ($assembly -like "*.dll") {
                It "The file $assembly should exist" {
					$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
					$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
					$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
                    Test-Path "$moduleRoot\$assembly" | Should -Be $true
                }
            }
            else {
                It "The file $assembly should load from the GAC" {
					$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
					$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
					$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
                    { Add-Type -AssemblyName $assembly } | Should -Not -Throw
                }
            }
        }
		
		foreach ($tag in $manifest.PrivateData.PSData.Tags)
		{
			It "Tags should have no spaces in name" {
				$moduleRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
				$manifest = ((Get-Content "$moduleRoot\AutomatedLabTest.psd1") -join "`n") | Invoke-Expression
				$files = Get-ChildItem "$moduleRoot\functions" -Recurse -File | Where-Object Name -like "*.ps1"
				$tag -match " " | Should -Be $false
			}
		}
	}
}