if ($IsLinux)
{
    # No validation on Linux yet, as we only test configurationitem usage
    return
}

$Timestamp = Get-Date -uformat "%Y%m%d-%H%M%S"
$PSVersion = $PSVersionTable.PSVersion.Major
$TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
$ProjectRoot = if ($env:APPVEYOR_BUILD_FOLDER) { $env:APPVEYOR_BUILD_FOLDER } else { (Resolve-Path "$PSScriptRoot/..").Path }

$modPath = Get-Item -Path (Join-Path $ProjectRoot requiredmodules)
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
  $sep = [io.path]::PathSeparator
  $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName,$sep,$env:PSModulePath
}

$modPath = Get-Item -Path (Join-Path $ProjectRoot publish)
if (-not $env:PSModulePath.Contains($modpath.FullName))
{
  $sep = [io.path]::PathSeparator
  $env:PSModulePath = '{0}{1}{2}' -f $modPath.FullName,$sep,$env:PSModulePath
}

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

        Set-Service WinRm -StartupType Manual -ErrorAction SilentlyContinue
        Start-Service WinRm -ErrorAction SilentlyContinue -Verbose
        Write-Host -ForegroundColor DarkYellow "Restarting VM"
        Enable-LabHostRemoting -Force
        Restart-AzVM -ResourceGroupName automatedlabintegration -Name inttestvm -Confirm:$false
        $retryCount = 0
        $so = New-PSSessionOption -IdleTimeout (New-TimeSpan -Hours 8).TotalMilliseconds
        while (-not $session -and $retryCount -lt 10)
        {
            try
            {
                Write-Host -ForegroundColor DarkYellow "Attempting to connect to $($depp.Outputs.hostname.Value)"
                Test-WSMan -ComputerName $depp.Outputs.hostname.Value
                Test-NetConnection -ComputerName $depp.Outputs.hostname.Value -CommonTCPPort WINRM
                $session = New-PSSession -ComputerName $depp.Outputs.hostname.Value -Credential $vmCredential -ErrorAction Stop -SessionOption $so
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
        $msifile = Get-ChildItem -Path $ProjectRoot -Recurse -Filter AutomatedLab.msi | Select-Object -First 1
        Copy-Item -ToSession $session -Path $msifile.FullName -Destination C:\al.msi
        Invoke-Command -Session $session -ScriptBlock {
            $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/powershell/powershell/releases/latest' -UseBasicParsing -ErrorAction SilentlyContinue
            msiexec /i C:\al.msi /L*v al.log
            $uri = ($release.assets | Where-Object name -like '*-win-x64.msi').browser_download_url
            if (-not $uri)
            {
                $uri = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/PowerShell-7.2.5-win-x64.msi'
            }
                
            Invoke-WebRequest -Uri $uri -UseBasicParsing -OutFile C:\PS7.msi -ErrorAction SilentlyContinue
             
            Start-Process -Wait -FilePath msiexec '/package C:\PS7.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=0 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=0 USE_MU=0 ENABLE_MU=0' -NoNewWindow -PassThru -ErrorAction SilentlyContinue
        }
        Send-ModuleToPSSession -Session $session -Module (Get-Module -ListAvailable Pester)[0] -IncludeDependencies -Force -Scope AllUsers
        Copy-Item -ToSession $session -Path "$ProjectRoot\.build\AlIntegrationEnv.ps1" -Destination C:\AlIntegrationEnv.ps1

        Write-Host -ForegroundColor DarkYellow "Running tests"
        $start = Get-Date
        Invoke-Command -Session $session -ScriptBlock {
            param
            (
                $Principal
            )
            [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', '1', 'Machine')
            Set-ExecutionPolicy Bypass -Scope LocalMachine -Force
            $env:AUTOMATEDLAB_TELEMETRY_OPTIN = 1
            $credential = [PSCredential]::new($principal.StorageAccountName, ($principal.StorageAccountKey | ConvertTo-SecureString -AsPlainText -Force))
            New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$($principal.StorageAccountName).file.core.windows.net\labsources" -Credential $credential
            Enable-LabHostRemoting -Force
            Set-PSFConfig -FullName AutomatedLab.LabSourcesLocation -Value Z: -PassThru | Register-PSFConfig
            Set-PSFConfig -FullName AutomatedLab.DoNotPrompt -Value $true -PassThru | Register-PSFConfig
            Set-PSFConfig -FullName AutomatedLab.AutoSyncLabSources -Value $false -PassThru | Register-PSFConfig

            $null = Get-PackageProvider -name Nuget -ForceBootstrap
            Install-LabAzureRequiredModule -Repository PSGallery -Scope AllUsers
            $securePassword = $principal.Password | ConvertTo-SecureString -AsPlainText -Force
            $credential = [PSCredential]::new($principal.ApplicationId, $securePassword)
            $null = Connect-AzAccount -ServicePrincipal -TenantId $principal.TenantId -Credential $credential -Subscription $principal.SubscriptionId -ErrorAction Stop
            & C:\AlIntegrationEnv.ps1
        } -ErrorAction SilentlyContinue -ArgumentList $principal

        $end = Get-Date
        Write-Host -ForegroundColor DarkYellow "Receiving test results, runtime $($end - $start)"
        Copy-Item -FromSession $session -Path C:\TestResult*.xml -Destination $ProjectRoot -ErrorAction SilentlyContinue
        Write-Host -ForegroundColor DarkYellow "Received $((Get-ChildItem -Path $ProjectRoot -Filter TestResult*.xml).Count) test results"
        If ($ENV:APPVEYOR_JOB_ID)
        {
            foreach ($testRes in (Get-ChildItem -Path $ProjectRoot -Filter TestResult*.xml))
            {
                    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $testRes.FullName )
            }
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
if ($TestResults.FailedCount -gt 0)
{
    throw "Failed '$($TestResults.FailedCount)' tests, build failed"
}