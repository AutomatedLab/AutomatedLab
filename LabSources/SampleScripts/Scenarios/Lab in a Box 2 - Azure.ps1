<#
In this scenario AutomatedLab builds a lab inside a lab. Thanks to nested virtualization in Hyper-V and Azure,
this can be done on a Windows Server 2016 or Windows 10 host machine.
This lab contains:
    -	ADDC1 with the role root domain controller
    -	AL1, the virtualized host machine on Windows Server Core 1709.
    -	optional AL2, another virtualized host machine on Windows Server 2016 with GUI. This machine also has the
            routing role to enable internet access for the whole lab.
    -	ADClient1 gives you graphical management access to the virtualized host.

Note: The domain controller and client are not required. These machine just add another level of comfort to have
graphical management of the virtual host machine and the lab inside.

After AutomatedLab has created the machines, it installs the Hyper-V roles on AL1 (and AL2) and ALClient1. Then the AutomatedLab
PowerShell modules are downloaded and installed on the virtual hosts. The ISO files are downloaded from the Azure LabSources folder
to the virtual hosts. If you have not synces it with your local LabSources folder, just call
"Sync-LabAzureLabSources -DoNotSkipOsIsos" to have your OS ISO images on Azure as well. ISOs on AL1 in order to deploy a lab
on the virtualized host so AL copied some files to the virtual host. Finally, the deployment script calls the sample script
"04 Single domain-joined server.ps1" on AL1 and deploys a lab in a lab.
#>

$azureDefaultLocation = 'West Europe' #COMMENT OUT -DefaultLocationName BELOW TO USE THE FASTEST LOCATION

$labName = 'ALTestLab2'

New-LabDefinition -Name $labName -DefaultVirtualizationEngine Azure

Add-LabAzureSubscription -DefaultLocationName $azureDefaultLocation

Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.25.1/24

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'= 1GB
    'Add-LabMachineDefinition:DomainName'= 'contoso.com'
}

Add-LabMachineDefinition -Name ALDC1 -Roles RootDC

Add-LabDiskDefinition -Name AL1D -DiskSizeInGb 100
Add-LabMachineDefinition -Name AL1 -Memory 32GB -OperatingSystem 'Windows Server Datacenter' -DiskName AL1D -Roles HyperV -AzureProperties @{RoleSize = 'Standard_D4s_v3'}

#Add-LabDiskDefinition -Name AL2D -DiskSizeInGb 100
#Add-LabMachineDefinition -Name AL2 -Memory 32GB -OperatingSystem 'Windows Server 2016 Datacenter (Desktop Experience)' -DiskName AL2D -Roles HyperV -AzureProperties @{RoleSize = 'Standard_D4s_v3'}

Add-LabMachineDefinition -Name ALClient1 -OperatingSystem 'Windows 10 Pro'

Install-Lab

$alServers = Get-LabVM | Where-Object Name -Like AL? #should be AL1 and AL2 (if available)

Invoke-LabCommand -ActivityName 'Install AutomatedLab and create LabSources folder' -ComputerName $alServers -ScriptBlock {

    #Add the AutomatedLab Telemetry setting to default to allow collection, otherwise will prompt during installation
    [System.Environment]::SetEnvironmentVariable('AUTOMATEDLAB_TELEMETRY_OPTOUT', '0')
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

    Install-PackageProvider -Name Nuget -ForceBootstrap -Force -ErrorAction Stop | Out-Null
    Install-Module -Name AutomatedLab -AllowClobber -Force -ErrorAction Stop

    Import-Module -Name AutomatedLab -ErrorAction Stop

    $dataVolume = Get-Volume -FileSystemLabel DataDisk* | Select-Object -First 1
    New-LabSourcesFolder -DriveLetter $dataVolume.DriveLetter -ErrorAction Stop

}

Invoke-LabCommand -ActivityName 'Copy ISOs from Azure LabSources folder' -ComputerName $alServers -ScriptBlock {

    Copy-Item -Path Z:\ISOs\* -Destination "$($dataVolume.DriveLetter):\LabSources\ISOs" -PassThru

} -PassThru

Invoke-LabCommand -ActivityName 'Deploy Test Lab' -ComputerName $alServers -ScriptBlock {

    & "$(Get-LabSourcesLocation)\SampleScripts\Introduction\04 Single domain-joined server.ps1"

}

Stop-LabVM -All -Wait #stop and deallocate all machines for cost reasons

Show-LabDeploymentSummary -Detailed