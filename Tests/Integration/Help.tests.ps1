<#
Ensure that all exported cmdlets offer help that is not auto-generated
#>
BeforeDiscovery {
    $rootpath = $PSScriptRoot
    $skippedCommands = @(
        # @raandree --> :)
        'Add-LabAzureWebAppDefinition'
        'Get-LabAzureWebApp'
        'Get-LabAzureWebApp'
        'Get-LabAzureWebAppDefinition'
        'Get-LabAzureWebAppStatus'
        'Get-LabAzureWebAppStatus'
        'New-LabAzureWebApp'
        'New-LabAzureWebApp'
        'Set-LabAzureWebAppContent'
        'Set-LabAzureWebAppContent'
        'Start-LabAzureWebApp'
        'Start-LabAzureWebApp'
        'Stop-LabAzureWebApp'
        'Stop-LabAzureWebApp'

        # This command should probably not be exported
        'Install-LWLabCAServers'

        # These are aliases
        'Get-LabPostInstallationActivity'
        'Disable-LabHostRemoting'
    )

    if (-not (Get-Module -List AutomatedLab.Common)) { Install-Module -Name AutomatedLab.Common -Force -SkipPublisherCheck -AllowClobber }
    if (-not (Get-Module -List PSFramework)) { Install-Module -Name PSFramework -Force -SkipPublisherCheck -AllowClobber }
    
    Import-Module -Name PSFramework, AutomatedLab.Common
    Import-Module -Name Pester
    if (-not $env:AUTOMATEDLAB_TELEMETRY_OPTIN)
    {
        [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', 'no', 'Machine')
        $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 'no'
    }
    
    $reqdModules = @(
        'AutomatedLabUnattended'
        'PSLog',
        'PSFileTransfer',
        'AutomatedLabDefinition',
        'AutomatedLabWorker',
        'HostsFile',
        'AutomatedLabNotifications',
        'AutomatedLab'
    )
    
    $oldPath = $env:PSModulePath
    $env:PSModulePath = (Resolve-Path -Path "$rootpath\..\..").Path
    $commands = foreach ($mod in $reqdModules)
    {
        Write-Host "Importing $(Resolve-Path -Path "$rootpath\..\..\$mod\$mod.psd1")"
        Import-Module -Name "$rootpath\..\..\$mod\$mod.psd1" -Force -ErrorAction SilentlyContinue
        Get-Command -Module $mod | Where-Object Name -notin $skippedCommands
    }
}

foreach ($command in $commands) {
    $commandName = $command.Name
    
    # The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets
    $Help = Get-Help $commandName -ErrorAction SilentlyContinue
	
	Describe "Test help for $commandName" {
        
		# If help is not found, synopsis in auto-generated help is the syntax diagram
		It "should not be auto-generated" -TestCases @{ Help = $Help } {
			$Help.Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
		}
        
		# Should be a description for every function
		It "gets description for $commandName" -TestCases @{ Help = $Help } {
			$Help.Description | Should -Not -BeNullOrEmpty
		}
        
		# Should be at least one example
		It "gets example code from $commandName" -TestCases @{ Help = $Help } {
			($Help.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
		}
	
		# Should be at least one example description
		It "gets example help from $commandName" -TestCases @{ Help = $Help } {
			($Help.Examples.Example.Remarks | Select-Object -First 1).Text | Should -Not -BeNullOrEmpty
		}
        
        Context "Test parameter help for $commandName" {
            
            $common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer', 'OutVariable', 'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable'
            
            $parameters = $command.ParameterSets.Parameters | Sort-Object -Property Name -Unique | Where-Object Name -notin $common
            $parameterNames = $parameters.Name
            $HelpParameterNames = $Help.Parameters.Parameter.Name | Sort-Object -Unique
            foreach ($parameter in $parameters) {
                $parameterName = $parameter.Name
                $parameterHelp = $Help.parameters.parameter | Where-Object Name -EQ $parameterName
			
				# Should be a description for every parameter
				It "gets help for parameter: $parameterName : in $commandName" -TestCases @{ parameterHelp = $parameterHelp } {
					$parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
				}
                
                if ($HelpTestSkipParameterType -and $HelpTestSkipParameterType[$commandName] -contains $parameterName) { continue }
                
                $codeType = $parameter.ParameterType.Name
                
                if ($parameter.ParameterType.FullName -in $HelpTestEnumeratedArrays) {
                    # Enumerations often have issues with the typename not being reliably available
                    $names = [Enum]::GetNames($parameter.ParameterType.DeclaredMembers[0].ReturnType)
					It "help for $commandName has correct parameter type for $parameterName" -TestCases @{ parameterHelp = $parameterHelp; names = $names } {
						$parameterHelp.parameterValueGroup.parameterValue | Should -be $names
					}
                }
                else {
                    # To avoid calling Trim method on a null object.
                    $helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
					# Parameter type in Help should match code
					It "help for $commandName has correct parameter type for $parameterName" -TestCases @{ helpType = $helpType; codeType = $codeType } {
						$helpType | Should -be $codeType
					}
                }
            }
            foreach ($helpParm in $HelpParameterNames) {
				# Shouldn't find extra parameters in help.
				It "finds help parameter in code: $helpParm : in $commandName" -TestCases @{ helpParm = $helpParm; parameterNames = $parameterNames } {
					$helpParm -in $parameterNames | Should -Be $true
				}
            }
        }
    }
}

$env:PSModulePath = $oldPath