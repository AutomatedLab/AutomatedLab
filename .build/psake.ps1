# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    $ProjectRoot = $env:APPVEYOR_BUILD_FOLDER
    $Timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'
}

Task Default -Depends BuildDebianPackage

Task Init {
    $lines
    Set-Location $ProjectRoot
    "`n"
}

Task BuildDebianPackage -Depends Test {
    if (-not $IsLinux)
    {
        return 
    }

    # Build debian package structure
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/local/share/powershell/Modules -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Assets -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Stores -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/Labs -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/usr/share/AutomatedLab/LabSources -Force
    $null = New-Item -ItemType Directory -Path ./deb/automatedlab/DEBIAN -Force

    # Create control file
    @"
Package: automatedlab
Version: $env:APPVEYOR_BUILD_VERSION
Maintainer: https://automatedlab.org
Description: Installs the pwsh module AutomatedLab in the global module directory
Section: utils
Architecture: amd64
Bugs: https://github.com/automatedlab/automatedlab/issues
Homepage: https://automatedlab.org
Pre-Depends: powershell
Installed-Size: $('{0:0}' -f ((Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Exclude .git -File -Recurse | Measure-Object Length -Sum).Sum /1mb))
"@ | Set-Content -Path ./deb/automatedlab/DEBIAN/control -Encoding UTF8

    # Copy content
    foreach ($source in [IO.DirectoryInfo[]]@('./AutomatedLab', './AutomatedLab.Recipe', './AutomatedLab.Ships', './AutomatedLabDefinition', './AutomatedLabNotifications', './AutomatedLabTest', './AutomatedLabUnattended', './AutomatedLabWorker', './HostsFile', './PSLog', './PSFileTransfer'))
    {
        $sourcePath = Join-Path -Path $source -ChildPath '/*'
        $modulepath = Join-Path -Path ./deb/automatedlab/usr/local/share/powershell/Modules -ChildPath "$($source.Name)/$($env:APPVEYOR_BUILD_VERSION)"
        $null = New-Item -ItemType Directory -Path $modulePath -Force
        Copy-Item -Path $sourcePath -Destination $modulePath -Force -Recurse
    }

    Save-Module -Name AutomatedLab.Common, newtonsoft.json, Ships, PSFramework, xPSDesiredStateConfiguration, xDscDiagnostics, xWebAdministration -Path ./deb/automatedlab/usr/local/share/powershell/Modules

    # Pre-configure LabSources for the user
    $confPath = "./deb/automatedlab/usr/local/share/powershell/Modules/AutomatedLab/$($env:APPVEYOR_BUILD_VERSION)/AutomatedLab.init.ps1"
    Add-Content -Path $confPath -Value 'Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Description "Location of lab sources folder" -Validation string -Value "/usr/share/AutomatedLab/LabSources"'

    Copy-Item -Path ./Assets/* -Recurse -Destination ./deb/automatedlab/usr/share/AutomatedLab/Assets -Force
    Copy-Item -Path ./LabSources/* -Recurse -Destination ./deb/automatedlab/usr/share/AutomatedLab/LabSources -Force

    # Update permissions on AL folder to allow non-root access to configs
    chmod -R 775 ./deb/automatedlab/usr/share/AutomatedLab

    # Build debian package and convert it to RPM
    dpkg-deb --build ./deb/automatedlab automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.deb
    sudo alien -r automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.deb
    Rename-Item -Path "*.rpm" -NewName automatedlab_NONSTABLEBETA_$($env:APPVEYOR_BUILD_VERSION)_x86_64.rpm
}

Task Test -Depends Init {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Ensure recent Pester version is actually used
    if (-not $IsLinux)
    {
        Import-Module -Name Pester -MinimumVersion 5.0.0 -Force

        # On master: Create resource group deployment, run expensive stuff
        # Prereq: $principal = New-AzADServicePrincipal -DisplayName 'automatedlabintegrationtester'
        # Prereq: $secret = $principal | New-AzADSpCredential -EndDate (Get-Date).AddYears(5)
        # Prereq: $account = get-azstorageaccount -ResourceGroupName AutomatedLabSources
        # Prereq: $saKey = ( $account | Get-AzStorageAccountKey)[0].Value
        # Store in AppVeyor: @{ApplicationId = $principal.AppId; Password = $secret.SecretText; TenantId = (Get-AzContext).Tenant.Id; StorageAccountKey = $saKey; StorageAccountName = $account.StorageAccountName; SubscriptionId = (Get-AzContext).Subscription.Id} | ConvertTo-Json -Compress | Set-Clipboard
        # Create and sync lab sources
        if ($env:APPVEYOR_REPO_BRANCH -eq 'master')
        {
            try
            {
                Write-Host -ForegroundColor DarkYellow "Is AzureServicePrincipal filled? $(-not [string]::IsNullOrWhiteSpace($env:AzureServicePrincipal))"
                $principal = $env:AzureServicePrincipal | ConvertFrom-Json

                $securePassword = $principal.Password | ConvertTo-SecureString -AsPlainText -Force
                $credential = [PSCredential]::new($principal.ApplicationId, $securePassword)
                $vmCredential = [PSCredential]::new('al', $securePassword)
                $null = Connect-AzAccount -ServicePrincipal -TenantId $principal.TenantId -Credential $credential -Subscription $principal.SubscriptionId -ErrorAction Stop

                Write-Host -ForegroundColor DarkYellow "Deploying to RG automatedlabintegration"
                $depp = New-AzResourceGroupDeployment -ResourceGroupName automatedlabintegration -Name "Integration$(Get-Date -Format yyyyMMdd)" -TemplateFile "$ProjectRoot\.build\arm.json" -adminPassword $securePassword
            
                # Prepare VM
                Write-Host -ForegroundColor DarkYellow "Attempting to enable PSRemoting and install Hyper-V"
                $tmpScript = New-Item ./prep.ps1 -Value 'Enable-PSRemoting -Force -SkipNetwork; Set-NetFirewallProfile -All -Enabled False; $null = Install-WindowsFeature Hyper-V -IncludeAll -IncludeMan;' -Force
                $null = Invoke-AzVmRunCommand -ResourceGroupName automatedlabintegration -VMName inttestvm -CommandId 'RunPowerShellScript' -ScriptPath $tmpScript.FullName -ErrorAction SilentlyContinue
                $tmpScript | Remove-Item

                Start-Service WinRm -ErrorAction SilentlyContinue -Verbose
                Write-Host -ForegroundColor DarkYellow "Restarting VM"
                Get-ChildItem wsman:\localhost\Client | Out-Host
                Restart-AzVM -ResourceGroupName automatedlabintegration -Name inttestvm -Confirm:$false
                $retryCount = 0
                while (-not $session -and $retryCount -lt 10)
                {
                    try
                    {
                        Write-Host -ForegroundColor DarkYellow "Attempting to connect to $($depp.Outputs.hostname.Value)"
                        Test-WSMan -ComputerName $depp.Outputs.hostname.Value
                        Test-NetConnection -ComputerName $depp.Outputs.hostname.Value -CommonTCPPort WINRM
                        Set-Item wsman:\localhost\Client\TrustedHosts $depp.Outputs.hostname.Value -Force -ErrorAction SilentlyContinue
                        Get-ChildItem wsman:\localhost\Client | Out-Host
                        $session = New-PSSession -ComputerName $depp.Outputs.hostname.Value -Credential $vmCredential -ErrorAction Stop
                    }
                    catch
                    {
                        Write-HOst -Fore Magenta $_.Exception.Message
                        $tmpScript = New-Item ./prep.ps1 -Value 'Enable-PSRemoting -Force -SkipNetwork; Set-NetFirewallProfile -All -Enabled False; $null = Install-WindowsFeature Hyper-V -IncludeAll -IncludeMan;' -Force
                        $null = Invoke-AzVmRunCommand -ResourceGroupName automatedlabintegration -VMName inttestvm -CommandId 'RunPowerShellScript' -ScriptPath $tmpScript.FullName -ErrorAction SilentlyContinue
                        $tmpScript | Remove-Item
                    }

                    Start-Sleep -Seconds 10
                    $retryCount++
                }

                Write-Host -ForegroundColor DarkYellow "Pushing MSI package"
                Add-VariableToPSSession -Session $session -PSVariable (Get-Variable principal)
                $msifile = Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Recurse -Filter AutomatedLab.msi | Select-Object -First 1
                Copy-Item -ToSession $session -Path $msifile -Destination C:\al.msi
                Invoke-Command -Session $session -ScriptBlock {msiexec /i C:\al.msi /L*v al.log}
                Send-ModuleToPSSession -Session $session -Module (Get-Module -ListAvailable Pester)[0] -IncludeDependencies -Force -Scope AllUsers
                Copy-Item -ToSession $session -Path "$ProjectRoot\.build\AlIntegrationEnv.ps1" -Destination C:\AlIntegrationEnv.ps1

                Write-Host -ForegroundColor DarkYellow "Running tests"
                Invoke-Command -Session $session -ScriptBlock {
                    [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', '1', 'Machine')
                    Set-ExecutionPolicy Bypass -Scope LocalMachine -Force
                    $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 1
                    $credential = [PSCredential]::new($principal.StorageAccountName, ($principal.StorageAccountKey | ConvertTo-SecureString -AsPlainText -Force))
                    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$($principal.StorageAccountName).file.core.windows.net\labsources" -Credential $credential
                    Enable-LabHostRemoting -Force
                    Set-PSFConfig -FullName AutomatedLab.LabSourcesLocation -Value Z: -PassThru | Register-PSFConfig
                    & C:\AlIntegrationEnv.ps1
                }

                Write-Host -ForegroundColor DarkYellow "Receiving test results"
                Copy-Item -FromSession $session -Path C:\Integrator.xml -Destination "$ProjectRoot\Integrator.xml"
                If ($ENV:APPVEYOR_JOB_ID)
                {
                (New-Object 'System.Net.WebClient').UploadFile(
                        "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
                        "$ProjectRoot\Integrator.xml" )
                }

            }
            finally
            {
                # After tests
                Write-Host -ForegroundColor DarkYellow "Deleting stuff from automatedlabintegration"
                $null = Get-AzVm -ResourceGroupName automatedlabintegration | Remove-AzVm -Force -ForceDeletion $true
                $null = Get-AzNetworkInterface -ResourceGroupName automatedlabintegration | Remove-AzNetworkInterface -Force
                $null = Get-AzVirtualNetwork -ResourceGroupName automatedlabintegration | Remove-AzVirtualNetwork -Force
                $null = Get-AzResource -ResourceGroupName automatedlabintegration | Remove-AzResource -Force
            }
        }

        # Gather test results. Store them in a variable and file
        $pesterOptions = [PesterConfiguration]::Default
        $pesterOptions.Run.Path = "$ProjectRoot\Tests"
        $pesterOptions.Run.PassThru = $true
        $pesterOptions.TestResult.OutputFormat = 'NUnitXml'
        $pesterOptions.TestResult.Enabled = $true
        $pesterOptions.TestResult.OutputPath = "$ProjectRoot\$TestFile"

        $TestResults = Invoke-Pester -Configuration $pesterOptions

        # In Appveyor?  Upload our tests! #Abstract this into a function?
        If ($ENV:APPVEYOR_JOB_ID)
        {
            (New-Object 'System.Net.WebClient').UploadFile(
                "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
                "$ProjectRoot\$TestFile" )
        }

        Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

        # Failed tests?
        # Need to tell psake or it will proceed to the deployment. Danger!
        if ($TestResults.FailedCount -gt 0)
        {
            throw "Failed '$($TestResults.FailedCount)' tests, build failed"
        }
    }
    "`n"
}
