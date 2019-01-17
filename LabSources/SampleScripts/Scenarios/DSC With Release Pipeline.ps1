$labName = 'DscReleasePipeline'

#--------------------------------------------------------------------------------------------------------------------
#----------------------- CHANGING ANYTHING BEYOND THIS LINE SHOULD NOT BE REQUIRED ----------------------------------
#----------------------- + EXCEPT FOR THE LINES STARTING WITH: REMOVE THE COMMENT TO --------------------------------
#----------------------- + EXCEPT FOR THE LINES CONTAINING A PATH TO AN ISO OR APP   --------------------------------
#--------------------------------------------------------------------------------------------------------------------

#create an empty lab template and define where the lab XML files and the VMs will be stored
New-LabDefinition -Name $labName -DefaultVirtualizationEngine HyperV

Add-LabIsoImageDefinition -Name Tfs2018 -Path $labSources\ISOs\tfsserver2018.3.iso #https://visualstudio.microsoft.com/downloads/
Add-LabIsoImageDefinition -Name SQLServer2016 -Path $labSources\ISOs\en_sql_server_2016_standard_with_service_pack_1_x64_dvd_9540929.iso

#make the network definition
Add-LabVirtualNetworkDefinition -Name $labName -AddressSpace 192.168.30.0/24
Add-LabVirtualNetworkDefinition -Name 'Default Switch' -HyperVProperties @{ SwitchType = 'External'; AdapterName = 'Ethernet' }

#and the domain definition with the domain admin account
Add-LabDomainDefinition -Name contoso.com -AdminUser Install -AdminPassword Somepass1

#these credentials are used for connecting to the machines. As this is a lab we use clear-text passwords
Set-LabInstallationCredential -Username Install -Password Somepass1

#defining default parameter values, as these ones are the same for all the machines
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:Network' = $labName
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
    'Add-LabMachineDefinition:DomainName' = 'contoso.com'
    'Add-LabMachineDefinition:DnsServer1' = '192.168.30.10'
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2016 Datacenter (Desktop Experience)'
    'Add-LabMachineDefinition:Gateway' = '192.168.30.50'
}

#The PostInstallationActivity is just creating some users
$postInstallActivity = @()
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name DRPDC01 -Memory 512MB -Roles RootDC -IpAddress 192.168.30.10 -PostInstallationActivity $postInstallActivity

# The good, the bad and the ugly
$netAdapter = @()
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch $labName -Ipv4Address 192.168.30.50
$netAdapter += New-LabNetworkAdapterDefinition -VirtualSwitch 'Default Switch' -UseDhcp
Add-LabMachineDefinition -Name DRPCASQL01 -Memory 4GB -Roles CaRoot, SQLServer2016, Routing -NetworkAdapter $netAdapter

# DSC Pull Server with SQL server backing, TFS Build Worker
$role = @(
    Get-LabMachineRoleDefinition -Role DSCPullServer -Properties @{ DoNotPushLocalModules = 'true'; DatabaseEngine = 'mdb' }
    Get-LabMachineRoleDefinition -Role TfsBuildWorker
)
Add-LabMachineDefinition -Name DRPPULL01 -Memory 2GB -Roles $role -OperatingSystem 'Windows Server Datacenter'

# Build Server
Add-LabMachineDefinition -Name DRPTFS01 -Memory 1GB -Roles Tfs2018

# DSC target nodes
1..2 | Foreach-Object {
    Add-LabMachineDefinition -Name "DRPSRV0$_" -Memory 1GB -OperatingSystem 'Windows Server 2016 Datacenter' # No GUI, we want DSC to configure our core servers
}

Install-Lab

Install-LabWindowsFeature -ComputerName (Get-LabVM -Role DSCPullServer) -FeatureName RSAT-AD-Tools

Enable-LabCertificateAutoenrollment -Computer -User

$buildSteps = @(
    @{
        "enabled"         = $true
        "continueOnError" = $false
        "alwaysRun"       = $false
        "displayName"     = "Execute Build.ps1"
        "task"            = @{
            "id"          = "e213ff0f-5d5c-4791-802d-52ea3e7be1f1" # We need to refer to a valid ID - refer to Get-LabBuildStep for all available steps
            "versionSpec" = "*"
        }
        "inputs"          = @{
            scriptType          = "filePath"
            scriptName          = ".Build.ps1"
            arguments           = "-resolveDependency"
            failOnStandardError = $false
        }
    }
)

<#
# Add optional release steps as well e.g.
$releaseSteps = @(
    @{
            enabled          = $true
            continueOnError  = $false
            alwaysRun        = $false
            timeoutInMinutes = 0
            definitionType   = 'task'
            version          = '*'
            name             = 'YOUR OWN DISPLAY NAME HERE' # e.g. Archive files $(message) or Archive Files
            taskid           = 'd8b84976-e99a-4b86-b885-4849694435b0'
            inputs           = @{
                                rootFolder = 'VALUE' # Type: filePath, Default: $(Build.BinariesDirectory), Mandatory: True
                                includeRootFolder = 'VALUE' # Type: boolean, Default: true, Mandatory: True
                                archiveType = 'VALUE' # Type: pickList, Default: default, Mandatory: True
                                tarCompression = 'VALUE' # Type: pickList, Default: gz, Mandatory: False
                                archiveFile = 'VALUE' # Type: filePath, Default: $(Build.ArtifactStagingDirectory)/$(Build.BuildId).zip, Mandatory: True
                                replaceExistingArchive = 'VALUE' # Type: boolean, Default: true, Mandatory: True
            }
        }

)

# Notice the differences here, the release steps have a slightly different syntax.
#>

# Clone the DSCInfraSample code and push the code to TFS while creating a new Project and the necessary build definitions
New-LabReleasePipeline -ProjectName 'ALSampleProject' -SourceRepository https://github.com/gaelcolas/DSCInfraSample -BuildSteps $buildSteps

# Job done
Show-LabDeploymentSummary -Detailed
