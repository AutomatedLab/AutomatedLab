function Request-LabCertificate
{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = 'Please enter the subject beginning with CN=')]
        [ValidatePattern('CN=')]
        [string]$Subject,

        [Parameter(HelpMessage = 'Please enter the SAN domains as a comma separated list')]
        [string[]]$SAN,

        [Parameter(HelpMessage = 'Please enter the Online Certificate Authority')]
        [string]$OnlineCA,

        [Parameter(Mandatory, HelpMessage = 'Please enter the Online Certificate Authority')]
        [string]$TemplateName,

        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    if ($OnlineCA -and -not (Get-LabVM -ComputerName $OnlineCA))
    {
        Write-ScreenInfo -Type Error -Message "Lab does not contain a VM called $OnlineCA, unable to request certificates from it"
        return
    }

    $computer = Get-LabVM -ComputerName $ComputerName

    $caGroups = $computer | Group-Object -Property DomainName

    foreach ($group in $caGroups)
    {
        # Empty group contains workgroup VMs
        if ([string]::IsNullOrWhiteSpace($group.Name) -and -not $OnlineCA)
        {
            Write-ScreenInfo -Type Error "Requesting a certificate from non-domain joined machines $($group.Group -join ',') requires the parameter OnlineCA to be used"
            return
        }

        if ($OnlineCA)
        {
            $onlineCAVM = Get-LabIssuingCA | Where-Object Name -eq $OnlineCA
        }
        else
        {
            $onlineCAVM = Get-LabIssuingCA -DomainName $group.Name
        }

        if (-not $onlineCAVM)
        {
            Write-ScreenInfo -Type Error -Message "No Certificate Authority was found in your lab for domain '$($group.Name)'. Unable to issue certificates for $($group.Group)"
            continue
        }

        # Especially on Azure, the CertSrv was sometimes stopped for no apparent reason
        Invoke-LabCommand -ComputerName $onlineCAVM -ScriptBlock { Start-Service CertSvc } -NoDisplay
        
        $PSBoundParameters.OnlineCA = $onlineCAVM.CaPath
        $variables = Get-Variable -Name PSBoundParameters
        $functions = Get-Command -Name Get-CATemplate, Request-Certificate, Find-CertificateAuthority, Sync-Parameter

        Invoke-LabCommand -ActivityName "Requesting certificate for template '$TemplateName'" -ComputerName $($group.Group) -ScriptBlock {

            Sync-Parameter -Command (Get-Command -Name Request-Certificate)
            Request-Certificate @ALBoundParameters

        } -Variable $variables -Function $functions -PassThru:$PassThru
    }

    Write-LogFunctionExit
}
