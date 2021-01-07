# Scenarios - Lab in a Box 1 - HyperV

INSERT TEXT HERE

```powershell
<#
        In this scenario AutomatedLab builds a lab inside a lab. Thanks to nested virtualization in Hyper-V and Azure,
        this can be done on a Windows Server 2016 or Windows 10 host machine.
        This lab contains:
        -	ADDC1 with the role root domain controller. This machine also has the routing role to enable
        internet access for the whole lab.
        -	AL1, the virtualized host machine on Windows Server 2019, which ideally runs on a server core.
        -	ADServer1 gives you graphical management access to the virtualized host if running on server core.

        Note: The domain controller and client are not required. These machines are just add another level of comfort to have
        graphical management of the virtual host machine and the lab inside.

        After AutomatedLab has created the machines, it enables nested virtualization on machine AL1 and installs the Hyper-V roles
        on AL1 and ADServer1. Then the AutomatedLab PowerShell modules are downloaded and installed on AL1. The only part missing are the
        ISOs on AL1 in order to deploy a lab on the virtualized host so AL copied some files to the virtual host. Finally, the
        deployment script calls the sample script "04 Single domain-joined server.ps1" on AL1 and deploys a lab in a lab.
#>

$labName = 'ALTestLab1'

New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

Add-LabVirtualNetworkDefinition -Name $labName
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:OperatingSystem'= 'Windows Server 2019 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Memory'= 1GB
    'Add-LabMachineDefinition:DomainName'= 'contoso.com'
}

$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name ALDC1 -Roles RootDC, Routing -NetworkAdapter $netAdapter

Add-LabMachineDefinition -Name AL1 -Memory 12GB -Roles HyperV #-OperatingSystem 'Windows Server Standard'

Add-LabMachineDefinition -Name ALServer1

Install-Lab

$alServers = Get-LabVM -ComputerName AL1

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
    Enable-LabHostRemoting -Force
    New-LabSourcesFolder -ErrorAction Stop
}

Copy-LabFileItem -ComputerName $alServers -DestinationFolderPath "C:\LabSources\ISOs" -Path `
$labSources\ISOs\14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO

Invoke-LabCommand -ActivityName 'Deploy Test Lab' -ComputerName $alServers -ScriptBlock {

    & "$(Get-LabSourcesLocation)\SampleScripts\Introduction\04 Single domain-joined server.ps1"

}

Show-LabDeploymentSummary -Detailed

```
