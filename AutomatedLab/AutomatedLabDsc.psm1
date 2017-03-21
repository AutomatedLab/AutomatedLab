#region Install-LabDscPullServer
function Install-LabDscPullServer
{
    # .ExternalHelp AutomatedLab.Help.xml
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = 15
    )
    
    Write-LogFunctionEntry
    
    $online = $true
    $lab = Get-Lab
    $roleName = [AutomatedLab.Roles]::DSCPullServer
    $requiredModules = 'xPSDesiredStateConfiguration', 'xDscDiagnostics'
    
    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role $roleName    
    if (-not $machines)
    {
        Write-ScreenInfo -Message 'No DSC Pull Server defined in this lab, so there is nothing to do'
        Write-LogFunctionExit
        return
    }

       
    if (-not (Get-LabVM -Role Routing) -and $lab.DefaultVirtualizationEngine -eq 'HyperV')
    {
        Write-ScreenInfo 'Routing Role not detected, installing DSC in offline mode.'
        $online = $false
    }
    else
    {
        Write-ScreenInfo 'Routing Role detected, installing DSC in online mode.'
    }

    if ($online)
    {
        $machinesOnline = $machines | ForEach-Object {
            Test-LabMachineInternetConnectivity -ComputerName $_ -AsJob
        } |
        Receive-Job -Wait -AutoRemoveJob |
        Where-Object { $_.TcpTestSucceeded } |
        ForEach-Object { $_.NetAdapter.SystemName }

        #if there are machines online, get the ones that are offline
        if ($machinesOnline)
        {
            $machinesOffline = (Compare-Object -ReferenceObject $machines.FQDN -DifferenceObject $machinesOnline).InputObject
        }
    
        #if there are machines offline or all machines are offline
        if ($machinesOffline -or -not $machinesOnline)
        {
            Write-Error "The machines $($machinesOffline -join ', ') are not connected to the internet. Switching to offline mode."
            $online = $false
        }
        else
        {
            Write-ScreenInfo 'All DSC Pull Servers can reach the internet.'
        }
    }
    
    $wrongPsVersion = Invoke-LabCommand -ComputerName $machines -ScriptBlock {
        $PSVersionTable | Add-Member -Name ComputerName -MemberType NoteProperty -Value $env:COMPUTERNAME -PassThru -Force
    } -PassThru -NoDisplay |
    Where-Object { $_.PSVersion.Major -lt 5 } |
    Select-Object -ExpandProperty ComputerName
    
    if ($wrongPsVersion)
    {
        Write-Error "The following machines have an unsupported PowerShell version. At least PowerShell 5.0 is required. $($wrongPsVersion -join ', ')"
        return
    }
    
    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15
    
    $ca = Get-LabIssuingCA
    if (-not $ca)
    {
        Write-Error 'This role requires a Certificate Authority but there is no one defined in the lab. Please make sure that one machine has the role CaRoot or CaSubordinate.'
        return
    }
    
    if (-not (Test-LabCATemplate -TemplateName DscPullSsl -ComputerName $ca))
    {
        New-LabCATemplate -TemplateName DscPullSsl -DisplayName 'Dsc Pull Sever SSL' -SourceTemplateName WebServer -ApplicationPolicy ServerAuthentication `
        -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName $ca -ErrorAction Stop
    }

    if ($Online)
    {        
        Invoke-LabCommand -ActivityName 'Setup Dsc Pull Server 1' -ComputerName $machines -ScriptBlock {
		param
		(
			[string[]]$requiredModules
		)
            Install-WindowsFeature -Name DSC-Service
            Install-PackageProvider -Name NuGet -Force
            Install-Module -Name $requiredModules -Force
        } -AsJob -PassThru -ArgumentList @($requiredModules) | Receive-Job -AutoRemoveJob -Wait | Out-Null #only interested in errors
    }
    else
    {
        if ((Get-Module -ListAvailable -Name $requiredModules).Count -eq 2)
        {
            Write-ScreenInfo "The required modules to install DSC ($($requiredModules -join ', ')) are found in PSModulePath"
        }
        else
        {
            Write-ScreenInfo "Downloading the modules '$($requiredModules -join ', ')' locally and copying them to the DSC Pull Servers."
        
            Install-PackageProvider -Name NuGet -Force | Out-Null
            Install-Module -Name $requiredModules -Force
        }

        $modulePaths = Get-Module -Name $requiredModules -ListAvailable | Select-Object -ExpandProperty ModuleBase | ForEach-Object { Split-Path -Path $_ -Parent }
        Copy-LabFileItem -Path $modulePaths -ComputerName $machines -DestinationFolder 'C:\Program Files\WindowsPowerShell'
    }
    
    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscPullServer\SetupDscPullServer.ps1,
    $labSources\PostInstallationActivities\SetupDscPullServer\DscTestConfig.ps1 -ComputerName $machines

    foreach ($machine in $machines)
    {
        $role = $machine.Roles | Where-Object Name -eq $roleName
        $doNotPushLocalModules = [bool]$role.Properties.DoNotPushLocalModules

        if (-not $doNotPushLocalModules)
        {
            $dscResources = Get-Module -ListAvailable | Where-Object { $_.Tags -contains 'DSCResource' -and $_.Name -notin $requiredModules }
            Write-ScreenInfo "Publishing local DSC resources: $($dscResources.Name -join ', ')..." -NoNewLine
            $modulePaths = $dscResources | Select-Object -ExpandProperty ModuleBase | ForEach-Object { Split-Path -Path $_ -Parent }
            Copy-LabFileItem -Path $modulePaths -ComputerName $machines -DestinationFolder 'C:\Program Files\WindowsPowerShell\Modules'
            Write-ScreenInfo 'finished'
        }
    }

    $jobs = @()

    foreach ($machine in $machines)
    {
        $cert = Request-LabCertificate -Subject "CN=*.$($machine.DomainName)" -TemplateName DscPullSsl -ComputerName $machine -PassThru -ErrorAction Stop
        
        $guid = (New-Guid).Guid
        
        $jobs += Invoke-LabCommand -ActivityName "Setting up DSC Pull Server on '$machine'" -ComputerName $machine -ScriptBlock { 
            param  
            (
                [Parameter(Mandatory)]
                [string]$ComputerName,

                [Parameter(Mandatory)]
                [string]$CertificateThumbPrint,

                [Parameter(Mandatory)]
                [string] $RegistrationKey
            )
    
            C:\SetupDscPullServer.ps1 -ComputerName $ComputerName -CertificateThumbPrint $CertificateThumbPrint -RegistrationKey $RegistrationKey
    
            C:\DscTestConfig.ps1
            Start-Job -ScriptBlock { Publish-DSCModuleAndMof -Source C:\DscTestConfig } | Wait-Job | Out-Null
    
        } -ArgumentList $machine, $cert.Thumbprint, $guid -AsJob -PassThru
    }
    
    Write-ScreenInfo -Message 'Waiting for configuration of DSC Pull Server to complete' -NoNewline
    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay

	$jobs = Install-LabWindowsFeature -ComputerName $machines -FeatureName Web-Mgmt-Tools -AsJob
	Write-ScreenInfo -Message 'Waiting for installation of IIS web admin tools to complete' -NoNewline
	Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay
    
    foreach ($machine in $machines)
    {
        $registrationKey = Invoke-LabCommand -ActivityName 'Get Registration Key created on the Pull Server' -ComputerName $machine -ScriptBlock {
            Get-Content 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt'
        } -PassThru
        
        $machine.InternalNotes.DscRegistrationKey = $registrationKey
    }
    
    Export-Lab
    
    Write-LogFunctionExit
}
#endregion Install-LabDscPullServer

#region Install-LabDscClient
function Install-LabDscClient
{
    # .ExternalHelp AutomatedLab.Help.xml
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,
        
        [Parameter(ParameterSetName = 'All')]
        [switch]$All,
        
        [string[]]$PullServer
    )
    
    if ($All)
    {
        $machines = Get-LabVM | Where-Object { $_.Roles.Name -notin 'DC', 'RootDC', 'FirstChildDC', 'DSCPullServer' }
    }
    else
    {
        $machines = Get-LabVM -ComputerName $ComputerName
    }
    
    if (-not $machines)
    {
        Write-Error 'Machines to configure DSC Pull not defined or not found in the lab.'
        return
    }
    
    Start-LabVM -ComputerName $machines -Wait
    
    if ($PullServer)
    {
        if (-not (Get-LabVM -ComputerName $PullServer | Where-Object { $_.Roles.Name -contains 'DSCPullServer' }))
        {
            Write-Error "The given DSC Pull Server '$PullServer' could not be found in the lab."
            return
        }
        else
        {
            $pullServerMachines = Get-LabVM -ComputerName $PullServer
        }
    }
    else
    {
        $pullServerMachines = Get-LabVM -Role DSCPullServer
    }
    
    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscClients\SetupDscClients.ps1 -ComputerName $machines
    
    foreach ($machine in $machines)
    {
        Invoke-LabCommand -ActivityName 'Setup DSC Pull Clients' -ComputerName $machine -ScriptBlock {
            param  
            (
                [Parameter(Mandatory)]
                [string[]]$PullServer,

                [Parameter(Mandatory)]
                [string[]]$RegistrationKey
            )
    
            C:\SetupDscClients.ps1 -PullServer $PullServer -RegistrationKey $RegistrationKey
        } -ArgumentList $pullServerMachines, $pullServerMachines.InternalNotes.DscRegistrationKey -PassThru
    }
}
#endregion Install-LabDscClient