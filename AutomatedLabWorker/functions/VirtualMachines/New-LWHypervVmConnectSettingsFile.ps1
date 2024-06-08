function New-LWHypervVmConnectSettingsFile
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [Cmdletbinding(PositionalBinding = $false)]
    #In the parameter block, 'HelpMessageResourceId' is misused to store the type that is stored in the config file.
    #'HelpMessageResourceId' does not have any effect on the parameter itself.
    param (
        [Parameter(HelpMessageResourceId = 'System.Boolean')]
        [bool]$AudioCaptureRedirectionMode = $false,
        
        [Parameter(HelpMessageResourceId = 'System.Boolean')]
        [bool]$EnablePrinterRedirection = $false,
        
        [Parameter(HelpMessageResourceId = 'System.Boolean')]
        [bool]$FullScreen = (Get-LabConfigurationItem -Name VMConnectFullScreen -Default $false),
        
        [Parameter(HelpMessageResourceId = 'System.Boolean')]
        [bool]$SmartCardsRedirection = $true,
        
        [Parameter(HelpMessageResourceId = 'System.String')]
        [string]$RedirectedPnpDevices,
        
        [Parameter(HelpMessageResourceId = 'System.String')]
        [bool]$ClipboardRedirection = $true,
        
        [Parameter(HelpMessageResourceId = 'System.Drawing.Size')]
        [string]$DesktopSize = (Get-LabConfigurationItem -Name VMConnectDesktopSize -Default '1366, 768'),

        [Parameter(HelpMessageResourceId = 'System.String')]
        [string]$VmServerName = $env:COMPUTERNAME,
        
        [Parameter(HelpMessageResourceId = 'System.String')]
        [string]$RedirectedUsbDevices,
        
        [Parameter(HelpMessageResourceId = 'System.Boolean')]
        [bool]$SavedConfigExists = $true,
        
        [Parameter(HelpMessageResourceId = 'System.Boolean')]
        [bool]$UseAllMonitors = (Get-LabConfigurationItem -Name VMConnectUseAllMonitors -Default $false),
        
        [Parameter(HelpMessageResourceId = 'Microsoft.Virtualization.Client.RdpOptions+AudioPlaybackRedirectionTyp')]
        [string]$AudioPlaybackRedirectionMode = 'AUDIO_MODE_REDIRECT',
        
        [Parameter(HelpMessageResourceId = 'System.Boolean')]
        [bool]$PrinterRedirection,
        
        [Parameter(HelpMessageResourceId = 'System.String')]
        [string]$RedirectedDrives = (Get-LabConfigurationItem -Name VMConnectRedirectedDrives -Default ''),
        
        [Parameter(Mandatory, HelpMessageResourceId = 'System.String')]
        [Alias('ComputerName')]
        [string]$VmName,
        
        [Parameter(HelpMessageResourceId = 'System.Boolean')]
        [bool]$SaveButtonChecked = $true
    )
    
    Write-LogFunctionEntry

    #AutomatedLab does not allow empty strings in the configuration, hence the detour.
    if ($RedirectedDrives -eq 'none')
    {
        $RedirectedDrives = ''
    }
    
    $machineVmConnectConfig = [AutomatedLab.Machines.MachineVmConnectConfig]::new()
    $parameters = $MyInvocation.MyCommand.Parameters

    $vm = Get-VM -Name $VmName

    foreach ($parameter in $parameters.GetEnumerator())
    {
        if (-not $parameter.Value.Attributes.HelpMessageResourceId)
        {
            continue
        }
        
        $value = Get-Variable -Name $parameter.Key -ValueOnly -ErrorAction SilentlyContinue
        $setting = [AutomatedLab.Machines.MachineVmConnectRdpOptionSetting]::new()
        
        $setting.Name = $parameter.Key
        $setting.Type = $parameter.Value.Attributes.HelpMessageResourceId
        $setting.Value = $value
        
        $machineVmConnectConfig.Settings.Add($setting)
        
        #Files will be stored in path 'C:\Users\<Username>\AppData\Roaming\Microsoft\Windows\Hyper-V\Client\1.0'
        $configFilePath = '{0}\Microsoft\Windows\Hyper-V\Client\1.0\vmconnect.rdp.{1}.config' -f $env:APPDATA, $vm.Id
        $configFileParentPath = Split-Path -Path $configFilePath -Parent
        if (-not (Test-Path -Path $configFileParentPath -PathType Container))
        {
            mkdir -Path $configFileParentPath -Force | Out-Null
        }
        $machineVmConnectConfig.Export($configFilePath)
    }
    
    Write-LogFunctionExit

}
