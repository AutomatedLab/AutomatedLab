@{
    RootModule             = 'AutomatedLabWorker.psm1'

    ModuleVersion          = '1.0.0'

    CompatiblePSEditions   = 'Core', 'Desktop'

    GUID                   = '3addac35-cd7a-4bd2-82f5-ab9c83a48246'

    Author                 = 'Raimund Andree, Per Pedersen, Jan-Hendrik Peters'

    CompanyName            = 'AutomatedLab Team'

    Copyright              = '2022'

    Description            = 'This module encapsulates all the work activities to prepare the lab'

    PowerShellVersion      = '5.1'

    DotNetFrameworkVersion = '4.0'

    FunctionsToExport      = @(
        'Add-LWAzureLoadBalancedPort',
        'Add-LWVMVHDX',
        'Checkpoint-LWAzureVM',
        'Checkpoint-LWHypervVM',
        'Connect-LWAzureLabSourcesDrive',
        'Disable-LWAzureAutoShutdown',
        'Dismount-LWAzureIsoImage',
        'Dismount-LWIsoImage',
        'Enable-LWAzureAutoShutdown',
        'Enable-LWAzureVMRemoting',
        'Enable-LWAzureWinRm',
        'Enable-LWHypervVMRemoting',
        'Enable-LWVMWareVMRemoting',
        'Get-LabAzureLoadBalancedPort',
        'Get-LWAzureAutoShutdown',
        'Get-LWAzureLoadBalancedPort',
        'Get-LWAzureNetworkSwitch',
        'Get-LWAzureSku',
        'Get-LWAzureVm',
        'Get-LWAzureVMConnectionInfo',
        'Get-LWAzureVmSize',
        'Get-LWAzureVmSnapshot',
        'Get-LWAzureVMStatus',
        'Get-LWAzureWindowsFeature',
        'Get-LWHypervVM',
        'Get-LWHypervVMDescription',
        'Get-LWHypervVMSnapshot',
        'Get-LWHypervVMStatus',
        'Get-LWHypervWindowsFeature',
        'Get-LWVMWareNetworkSwitch',
        'Get-LWVMWareVMStatus',
        'Initialize-LWAzureVM',
        'Install-LWAzureWindowsFeature',
        'Install-LWHypervWindowsFeature',
        'Install-LWLabCAServers',
        'Install-LWLabCAServers2008',
        'Invoke-LWCommand',
        'Mount-LWAzureIsoImage',
        'Mount-LWIsoImage',
        'New-LabAzureResourceGroupDeployment',
        'New-LWAzureLoadBalancer',
        'New-LWAzureNetworkSwitch',
        'New-LWHypervNetworkSwitch',
        'New-LWHypervVM',
        'New-LWHypervVMConnectSettingsFile',
        'New-LWReferenceVHDX',
        'New-LWVHDX',
        'New-LWVMWareVM',
        'Remove-LWAzureLoadBalancer',
        'Remove-LWAzureNetworkSwitch',
        'Remove-LWAzureVM',
        'Remove-LWAzureVmSnapshot',
        'Remove-LWAzureRecoveryServicesVault',
        'Remove-LWHypervVM',
        'Remove-LWHypervVMSnapshot',
        'Remove-LWNetworkSwitch',
        'Remove-LWVHDX',
        'Remove-LWVMWareVM',        
        'Repair-LWHypervNetworkConfig',
        'Remove-LWHypervVMConnectSettingsFile',
        'Restore-LWAzureVmSnapshot',
        'Restore-LWHypervVMSnapshot',
        'Save-LWHypervVM',
        'Save-LWVMWareVM',
        'Set-LWAzureDnsServer',
        'Set-LWHypervVMDescription',
        'Start-LWAzureVM',
        'Start-LWHypervVM',
        'Start-LWVMWareVM',
        'Stop-LWAzureVM',
        'Stop-LWHypervVM',
        'Stop-LWVMWareVM',
        'Test-IpInSameSameNetwork',
        'Uninstall-LWAzureWindowsFeature',
        'Uninstall-LWHypervWindowsFeature',
        'Wait-LWAzureRestartVM',
        'Wait-LWHypervVMRestart',
        'Wait-LWLabJob',
        'Wait-LWVMWareRestartVM'
    )

    RequiredModules        = @( )

    NestedModules          = @( )

    FileList               = @( )


    PrivateData            = @{

        PSData = @{
            Prerelease   = ''
            Tags         = @('LabWorker', 'Lab', 'LabAutomation', 'HyperV', 'Azure')
            LicenseUri   = 'https://github.com/AutomatedLab/AutomatedLab/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/AutomatedLab/AutomatedLab'
            IconUri      = 'https://github.com/AutomatedLab/AutomatedLab/blob/master/Assets/Automated-Lab_icon256.png'
            ReleaseNotes = ''
        }
    }
}
