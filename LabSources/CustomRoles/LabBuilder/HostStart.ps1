param(
    [Parameter(Mandatory)]
    [string]
    $ComputerName,

    [string]
    $Repository = 'PSGallery',

    [string]
    $LabSourcesDrive = 'C',

    [ValidateSet('yes', 'no')]
    $TelemetryOptIn = 'no'
)

if (-not (Get-Lab -ErrorAction SilentlyContinue))
{
    Import-Lab -Name $data.Name -NoDisplay -NoValidation
}

# Enable Virtualization
$vm = Get-LabVm -ComputerName $ComputerName
Write-ScreenInfo -Message "Starting deployment of Lab Builder on $vm"

if (-not $vm.Roles.Name -contains 'HyperV')
{
    Write-ScreenInfo -Message "Exposing virtualization extensions on $vm" -Type Verbose
    Stop-LabVm -ComputerName $vm -Wait
    $hyperVvm = Hyper-V\Get-VM -Name $vm.ResourceName
    $hyperVvm | Set-VMProcessor -ExposeVirtualizationExtensions $true
    Start-LabVM $vm -Wait
    Install-LabWindowsFeature -FeatureName Hyper-V -ComputerName $vm -IncludeAllSubFeature
    Restart-LabVm -wait -ComputerName $vm
}

Write-ScreenInfo -Message "Taking additional disk(s) online" -Type Verbose
Invoke-LabCommand -ComputerName $ComputerName -ScriptBlock {
    $disk = Get-Disk | Where-Object IsOffline
    $disk | Set-Disk -IsOffline $false
    $disk | Set-Disk -IsReadOnly $false

    $disk | Where-Object PartitionStyle -notin 'MBR', 'GPT' | Initialize-Disk -PartitionStyle GPT
    if (-not ($disk | get-partition | get-volume | where driveletter))
    {
        $disk | New-Partition -UseMaximumSize -AssignDriveLetter
    }
} -NoDisplay

$features = @(
    'Web-Default-Doc',
    'Web-Dir-Browsing',
    'Web-Http-Errors',
    'Web-Static-Content',
    'Web-Http-Redirect',
    'Web-DAV-Publishing',
    'Web-Http-Logging',
    'Web-Stat-Compression',
    'Web-Filtering',
    'Web-Net-Ext',
    'Web-Net-Ext45',
    'Web-Asp-Net',
    'Web-Asp-Net45',
    'Web-CGI',
    'Web-ISAPI-Ext',
    'Web-ISAPI-Filter',
    'Web-Mgmt-Console',
    'Web-Windows-Auth'
)
Install-LabWindowsFeature -FeatureName $features -ComputerName $ComputerName -NoDisplay
$iisModuleUrl = 'https://download.visualstudio.microsoft.com/download/pr/c887d56b-4667-4e1d-9b6c-95a32dd65622/97e3eef489af8a6950744c4f9bde73c0/dotnet-hosting-5.0.8-win.exe'
$iisModulePath = Get-LabInternetFile -uri $iisModuleUrl -Path $labsources/SoftwarePackages -PassThru
Install-LabSoftwarePackage -Path $iisModulePath.FullName -CommandLine '/S' -ComputerName $ComputerName -NoDisplay

$pwshUrl = 'https://github.com/PowerShell/PowerShell/releases/download/v7.2.4/PowerShell-7.2.4-win-x64.msi'
$pwshPath = Get-LabInternetFile -uri $pwshUrl -Path $labsources/SoftwarePackages -PassThru
Install-LabSoftwarePackage -Path $pwshPath.FullName -ComputerName $ComputerName -NoDisplay

$netFullUrl = Get-LabConfigurationItem dotnet48DownloadLink
$netFullPath = Get-LabInternetFile -uri $netFullUrl -Path $labsources/SoftwarePackages -PassThru
Install-LabSoftwarePackage -Path $netFullPath.FullName -ComputerName $ComputerName -NoDisplay -CommandLine '/q /norestart /log c:\DeployDebug\dotnet48.txt' -UseShellExecute

Write-ScreenInfo -Message "Downloading pode" -Type Verbose
$downloadPath = Join-Path -Path (Get-LabSourcesLocationInternal -Local) -ChildPath SoftwarePackages\pode
if (-not (Test-LabHostConnected) -and -not (Test-Path $downloadPath))
{
    Write-ScreenInfo -Type Error -Message "$env:COMPUTERNAME is offline and pode has never been downloaded to $downloadPath"
    return
}

if (-not (Test-path -Path $downloadPath))
{
    Save-Module -Name pode -Path (Join-Path -Path (Get-LabSourcesLocationInternal -Local) -ChildPath SoftwarePackages) -Repository $Repository
}
Copy-LabFileItem -Path $downloadPath -ComputerName $vm -DestinationFolderPath (Join-Path $env:ProgramFiles -ChildPath PowerShell\Modules)
Copy-LabFileItem -Path $downloadPath -ComputerName $vm -DestinationFolderPath (Join-Path $env:ProgramFiles -ChildPath WindowsPowerShell\Modules)


$session = New-LabPSSession -Machine $vm

Write-ScreenInfo -Message 'Copying AutomatedLab to build machine' -Type Verbose
$module = Get-Module -ListAvailable -Name AutomatedLabCore | Sort-Object Version | Select-Object -Last 1
Send-ModuleToPSSession -Module $module -Session $session -WarningAction SilentlyContinue -IncludeDependencies

Write-ScreenInfo -Message ('Mirroring LabSources to {0} - this could take a while. You have {1:N2}GB of data.' -f $vm, ((Get-ChildItem $labsources -File -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB))
Copy-LabFileItem -Path $labSources -ComputerName $ComputerName -DestinationFolderPath "$($LabSourcesDrive):\" -Recurse
$lsRoot = "$($LabSourcesDrive):\$(Split-Path -Leaf -Path $labSources)"

$webConfig = @"
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <remove name="WebDAV" />
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
        <remove name="ExtensionlessUrlHandler-Integrated-4.0" />
        <add name="ExtensionlessUrlHandler-Integrated-4.0" path="*." verb="*" type="System.Web.Handlers.TransferRequestHandler" preCondition="integratedMode,runtimeVersionv4.0" />
        <remove name="ExtensionlessUrl-Integrated-4.0" />
        <add name="ExtensionlessUrl-Integrated-4.0" path="*." verb="*" type="System.Web.Handlers.TransferRequestHandler" preCondition="integratedMode,runtimeVersionv4.0" />
      </handlers>

      <modules>
        <remove name="WebDAVModule" />
      </modules>

      <aspNetCore processPath="powershell.exe" arguments=".\server.ps1" stdoutLogEnabled="true" stdoutLogFile=".\logs\stdout" hostingModel="OutOfProcess"/>

      <security>
        <authorization>
          <remove users="*" roles="" verbs="" />
          <add accessType="Allow" users="*" verbs="GET,HEAD,POST,PUT,DELETE,DEBUG,OPTIONS" />
        </authorization>
      </security>
    </system.webServer>
  </location>
</configuration>
"@

Invoke-LabCommand -ComputerName $ComputerName -Variable (Get-Variable TelemetryOptIn,lsRoot) -ScriptBlock {    
    [Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTIN', $TelemetryOptIn, 'Machine')
    Set-PSFConfig -FullName AutomatedLab.LabSourcesLocation -Value $lsRoot -PassThru | Register-PSFConfig -Scope SystemDefault
} -NoDisplay

Restart-LabVm -Wait -ComputerName $ComputerName -NoDisplay

$credential = $vm.GetCredential((Get-Lab))

Invoke-LabCommand -ComputerName $ComputerName -ActivityName 'Registering website' -Variable (Get-Variable webConfig, credential) -ScriptBlock {
    $null = mkdir C:\LabBuilder -ErrorAction SilentlyContinue
    $webConfig | Set-Content -Path C:\LabBuilder\web.config

    Remove-Website -Name 'Default Web Site' -ErrorAction SilentlyContinue
    Remove-WebAppPool -Name DefaultAppPool -ErrorAction SilentlyContinue

    if (-not (Get-IISAppPool -Name LabBuilder -ErrorAction SilentlyContinue -WarningAction SilentlyContinue))
    {
        $null = New-WebAppPool -Name LabBuilder -Force
    }

    if (-not (Get-WebSite -Name LabBuilder -ErrorAction SilentlyContinue -WarningAction SilentlyContinue))
    {
        $null = New-WebSite -Name LabBuilder -ApplicationPool LabBuilder -PhysicalPath C:\LabBuilder
    }

    Set-WebConfiguration system.webServer/security/authentication/anonymousAuthentication -PSPath IIS:\ -Location LabBuilder -Value @{enabled = "False" }
    Set-WebConfiguration system.webServer/security/authentication/windowsAuthentication -PSPath IIS:\ -Location LabBuilder -Value @{enabled = "True" }

    Remove-WebConfigurationProperty -PSPath IIS:\ -Location LabBuilder -filter system.webServer/security/authentication/windowsAuthentication/providers -name "."

    Add-WebConfiguration -Filter system.webServer/security/authentication/windowsAuthentication/providers -PSPath IIS:\ -Location LabBuilder -Value Negotiate
    Add-WebConfiguration -Filter system.webServer/security/authentication/windowsAuthentication/providers -PSPath IIS:\ -Location LabBuilder -Value NTLM

    Set-ItemProperty -Path IIS:\AppPools\LabBuilder -Name processmodel.identityType -Value 3
    Set-ItemProperty -Path IIS:\AppPools\LabBuilder -Name processmodel.userName -Value $credential.UserName
    Set-ItemProperty -Path IIS:\AppPools\LabBuilder -Name processmodel.password -Value $credential.GetNetworkCredential().Password
    Set-ItemProperty -Path IIS:\AppPools\LabBuilder -Name processmodel.idleTimeout -Value '00:00:00'
    Set-ItemProperty -Path IIS:\AppPools\LabBuilder -Name recycling.periodicRestart.time -Value '00:00:00'

    Restart-WebAppPool -Name LabBuilder

    $os = Get-LabAvailableOperatingSystem
} -NoDisplay

Copy-LabFileItem -Path $PSScriptRoot\server.ps1 -ComputerName $vm -DestinationFolderPath C:\LabBuilder
