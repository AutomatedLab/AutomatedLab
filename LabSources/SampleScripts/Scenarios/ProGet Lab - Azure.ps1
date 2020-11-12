$labName = "ProGet_$((1..6 | ForEach-Object { [char[]](97..122) | Get-Random }) -join '')"
$azureLocation = 'West Europe'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------


New-LabDefinition -Name $labName -DefaultVirtualizationEngine Azure
Add-LabAzureSubscription -DefaultLocationName $azureLocation

Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.110.0/24

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
Add-LabMachineDefinition -Name PGDC1 -Memory 1GB -Roles RootDC -IpAddress 192.168.110.10 -PostInstallationActivity $postInstallActivity

#web server
$role = Get-LabPostInstallationActivity -CustomRole ProGet5 -Properties @{
    ProGetDownloadLink = 'https://s3.amazonaws.com/cdn.inedo.com/downloads/proget/ProGetSetup5.2.13.exe'
    SqlServer = 'PGSql1'
}
Add-LabMachineDefinition -Name PGWeb1 -Memory 1GB -Roles WebServer -IpAddress 192.168.110.51 -PostInstallationActivity $role

#SQL server
Add-LabIsoImageDefinition -Name SQLServer2016 -Path $labSources\ISOs\en_sql_server_2016_standard_with_service_pack_2_x64_dvd_12124191.iso
Add-LabMachineDefinition -Name PGSql1 -Memory 2GB -Roles SQLServer2016 -IpAddress 192.168.110.52

#client
Add-LabMachineDefinition -Name PGClient1 -Memory 2GB -OperatingSystem 'Windows 10 Pro' -IpAddress 192.168.110.54

Install-Lab

#Install software to all lab machines
$machines = Get-LabVM
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

$progetServer = Get-LabVM | Where-Object { $_.PostInstallationActivity.RoleName -like 'ProGet*' }
$progetUrl = "http://$($progetServer.FQDN)/nuget/PowerShell"
$firstDomain = (Get-Lab).Domains[0]
$nuGetApiKey = "$($firstDomain.Administrator.UserName)@$($firstDomain.Name):$($firstDomain.Administrator.Password)"
Invoke-LabCommand -ActivityName RegisterPSRepository -ComputerName PGClient1 -ScriptBlock {
    try
    {
        #https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=netcore-2.0#System_Net_SecurityProtocolType_SystemDefault
        if ($PSVersionTable.PSVersion.Major -lt 6 -and [Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12')
        {
            Write-Verbose -Message 'Adding support for TLS 1.2'
            [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
        }
    }
    catch
    {
        Write-Warning -Message 'Adding TLS 1.2 to supported security protocols was unsuccessful.'
    }
    Install-PackageProvider -Name NuGet -Force

    $targetPath = 'C:\ProgramData\Microsoft\Windows\PowerShell\PowerShellGet'
    if (-not (Test-Path -Path $targetPath))
    {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    }

    $sourceNugetExe = 'http://nuget.org/NuGet.exe'
    $targetNugetExe = Join-Path -Path $targetPath -ChildPath NuGet.exe
    Invoke-WebRequest $sourceNugetExe -OutFile $targetNugetExe
    
    Register-PSRepository -Name Internal -SourceLocation $progetUrl -PublishLocation $progetUrl -InstallationPolicy Trusted

    #--------------------------------------------------------------------------------

    (New-ScriptFileInfo -Path C:\SomeScript2.ps1 -Version 1.0 -Author Me -Description Test -PassThru -Force) + 'Get-Date' | Out-File C:\SomeScript.ps1
    Publish-Script -Path C:\SomeScript.ps1 -Repository Internal -NuGetApiKey $nuGetApiKey
} -Variable (Get-Variable -Name nuGetApiKey, progetUrl)

Show-LabDeploymentSummary -Detailed
