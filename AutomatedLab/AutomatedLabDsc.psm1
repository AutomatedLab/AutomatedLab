#region Install-LabDscPullServer
function Install-LabDscPullServer
{
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = 15
    )
	
    Write-LogFunctionEntry
	
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
        
        Invoke-LabCommand -ActivityName 'Setup Dsc Pull Server 1' -ComputerName $machine -ScriptBlock {
            Install-WindowsFeature -Name DSC-Service
            Install-PackageProvider -Name NuGet -Force
            Install-Module xPSDesiredStateConfiguration, xDscDiagnostics -Force            
        }
        
        Invoke-LabCommand -ActivityName "Setting up DSC Pull Server on '$machine'" -ComputerName $machine -ScriptBlock { 
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
    
        } -ArgumentList $machine, $cert.Thumbprint, (New-Guid) -PassThru
    }
    
    Write-ScreenInfo -Message 'Waiting for configuration of routing to complete' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -Timeout $InstallationTimeout -NoDisplay
    
    Write-LogFunctionExit
}
#endregion Install-LabDscPullServer