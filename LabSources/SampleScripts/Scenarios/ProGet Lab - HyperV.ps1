$labName = 'ProGet'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------


New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.110.0/24
Add-LabVirtualNetworkDefinition -Name External -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Wi-Fi' }

Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.110.10'
    'Add-LabMachineDefinition:Gateway' = '192.168.110.10'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
}

#DC
$postInstallActivity = Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.110.10
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch External -UseDhcp
Add-LabMachineDefinition -Name PGDC1 -Memory 1GB -Roles RootDC, Routing -NetworkAdapter $netAdapter -PostInstallationActivity $postInstallActivity

#web server
$role = Get-LabPostInstallationActivity -CustomRole ProGet5 -Properties @{
    ProGetDownloadLink = 'https://s3.amazonaws.com/cdn.inedo.com/downloads/proget/ProGetSetup5.0.10.exe'
    SqlServer = 'PGSql1'
}
Add-LabMachineDefinition -Name PGWeb1 -Memory 1GB -Roles WebServer -IpAddress 192.168.110.51 -PostInstallationActivity $role


#SQL server
Add-LabIsoImageDefinition -Name SQLServer2016 -Path $labSources\ISOs\en_sql_server_2016_standard_with_service_pack_1_x64_dvd_9540929.iso
Add-LabMachineDefinition -Name PGSql1 -Memory 2GB -Roles SQLServer2016 -IpAddress 192.168.110.52

#client
Add-LabMachineDefinition -Name PGClient1 -Memory 2GB -OperatingSystem 'Windows 10 Pro' -IpAddress 192.168.110.54

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\ClassicShell.exe -CommandLine '/quiet ADDLOCAL=ClassicStartMenu' -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Invoke-LabCommand -ActivityName RegisterPSRepository -ComputerName PGClient1 -ScriptBlock {
    Install-PackageProvider -Name NuGet -Force

    $targetPath = 'C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet'
    if (-not (Test-Path -Path $targetPath))
    {
        mkdir -Path $targetPath -Force | Out-Null
    }

    $sourceNugetExe = 'http://nuget.org/NuGet.exe'
    $targetNugetExe = Join-Path -Path $targetPath -ChildPath NuGet.exe
    Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
    
    $path = "http://PGWeb1.contoso.com:8624/nuget/Internal"
    Register-PSRepository -Name Internal -SourceLocation $path -PublishLocation $path -InstallationPolicy Trusted

    #--------------------------------------------------------------------------------

    (New-ScriptFileInfo -Path C:\SomeScript2.ps1 -Version 1.0 -Author Me -Description Test -PassThru -Force) + 'Get-Date' | Out-File C:\SomeScript.ps1
    Publish-Script -Path C:\SomeScript.ps1 -Repository Internal -NuGetApiKey 'Install@Contoso.com:Somepass1'

}

Show-LabDeploymentSummary -Detailed