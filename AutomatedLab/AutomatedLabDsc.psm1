#region Install-LabDscPullServer
function Install-LabDscPullServer
{
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = 15
    )
    
    Write-LogFunctionEntry
    
    $labSources = Get-LabSourcesLocation
    $roleName = [AutomatedLab.Roles]::DSCPullServer
    
    if (-not (Get-LabMachine))
    {
        Write-Warning -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        Write-LogFunctionExit
        return
    }
    
    if (-not (Get-LabMachine -Role Routing))
    {
        Write-Error 'This role requires the lab to have an internet connection. However there is no machine with the Routing role in the lab. Please make sure that one machine has also an internet facing network adapter and the routing role.'
        return
    }
    
    $machines = Get-LabMachine -Role $roleName
    
    if (-not $machines)
    {
        return
    }
    
    if (-not (Test-LabMachineInternetConnectivity -ComputerName (Get-LabMachine -Role Routing)))
    {
        Write-Error "The lab is not connected to the internet. Internet connectivity is required to install DSC"
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
    
    New-LabCATemplate -TemplateName DscPullSsl -DisplayName 'Dsc Pull Sever SSL' -SourceTemplateName WebServer -ApplicationPolicy ServerAuthentication `
    -EnrollmentFlags Autoenrollment -PrivateKeyFlags AllowKeyExport -Version 2 -SamAccountName 'Domain Computers' -ComputerName $ca

    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscPullServer\SetupDscPullServer.ps1,
    $labSources\PostInstallationActivities\SetupDscPullServer\DscTestConfig.ps1 -ComputerName $machines
        
    Invoke-LabCommand -ActivityName 'Setup Dsc Pull Server 1' -ComputerName $machines -ScriptBlock {
        Install-WindowsFeature -Name DSC-Service
        Install-PackageProvider -Name NuGet -Force
        Install-Module xPSDesiredStateConfiguration, xDscDiagnostics -Force            
    } -AsJob -PassThru | Receive-Job -AutoRemoveJob -Wait | Out-Null #only interested in errors
    
    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscPullServer\SetupDscPullServer.ps1,
    $labSources\PostInstallationActivities\SetupDscPullServer\DscTestConfig.ps1 -ComputerName $machines

    $jobs = @()

    foreach ($machine in $machines)
    {
        $psVersion = Invoke-LabCommand -ActivityName 'Get PowerShell Version' -ComputerName $machine -ScriptBlock { $PSVersionTable } -PassThru
        if (-not $psVersion.PSVersion -ge '5.0')
        {
            Write-Error 'The DSC Pull Server role requires at least PowerShell 5.0. Please install it before installing this role.'
            continue
        }
        
        $cert = Request-LabCertificate -Subject "CN=*.$($machine.DomainName)" -TemplateName DscPullSsl -ComputerName $machine -PassThru
        
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
    
        } -ArgumentList $machine, $cert.Thumbprint, (New-Guid) -AsJob -PassThru
    }
    
    Write-ScreenInfo -Message 'Waiting for configuration of DSC Pull Server to complete' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay
    
    foreach ($machine in $machines)
    {
        $registrationKey = Invoke-LabCommand -ActivityName 'Get Registration Key created on the Pull Server' -ComputerName $machine -ScriptBlock {
            Get-Content 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt'
        } -PassThru
        
        $machine.Notes.DscRegistrationKey = $registrationKey
    }
    
    Export-Lab
    
    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscClients\SetupDscClients.ps1 -ComputerName (Get-LabMachine)
    
    Write-LogFunctionExit
}
#endregion Install-LabDscPullServer

#region Install-LabDscClient
function Install-LabDscClient
{
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,
        
        [Parameter(ParameterSetName = 'All')]
        [switch]$All,
        
        [string]$PullServer
    )
    
    $labSources = Get-LabSourcesLocation
    
    if ($All)
    {
        $machines = Get-LabMachine | Where-Object { $_.Roles.Name -notin 'DC', 'RootDC', 'FirstChildDC' -and $_.Name -ne $pullServer.Name }
    }
    else
    {
        $machines = Get-LabMachine -ComputerName $ComputerName
    }
    
    if (-not $machines)
    {
        Write-Error 'Machines to configure DSC Pull not defined or not found in the lab.'
        return
    }
    
    Start-LabVM -ComputerName $machines -Wait
    
    if (-not (Get-LabMachine -ComputerName $PullServer | Where-Object { $_.Roles.Name -contains 'DSCPullServer' }))
    {
        Write-Error "The given DSC Pull Server '$PullServer' could not be found in the lab."
        return
    }
    else
    {
        $pullServerMachine = Get-LabMachine -ComputerName $PullServer
    }
    
    $registrationKey = Invoke-LabCommand -ActivityName 'Get Registration Key created on the Pull Server' -ComputerName $pullServerMachine -ScriptBlock {
        Get-Content 'C:\Program Files\WindowsPowerShell\DscService\RegistrationKeys.txt'
    } -PassThru
    
    if (-not $registrationKey)
    {
        Write-Error "Could not retrieve regitration key from DSC Pull Server '$pullServerMachine'. Was the DSC Pull Server successfully installed?"
        return
    }
    
    Copy-LabFileItem -Path $labSources\PostInstallationActivities\SetupDscClients\SetupDscClients.ps1 -ComputerName $machines
    
    foreach ($machine in $machines)
    {
        Invoke-LabCommand -ActivityName 'Setup machines into Dsc Pull Mode' -ComputerName $machine -ScriptBlock { 
            param
            (
                [Parameter(Mandatory = $true)]
                [string]$PullServer,

                [Parameter(Mandatory = $true)]
                [string] $RegistrationKey
            )
        
            C:\SetupDscClients.ps1 -PullServer $PullServer -RegistrationKey $RegistrationKey
        } -ArgumentList $pullServerMachine.FQDN, $registrationKey
    }
}
#endregion Install-LabDscClient