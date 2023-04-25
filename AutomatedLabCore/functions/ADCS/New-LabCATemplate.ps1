function New-LabCATemplate
{

    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,

        [string]$DisplayName,

        [Parameter(Mandatory)]
        [string]$SourceTemplateName,

        [ValidateSet('EFS_RECOVERY', 'Auto Update CA Revocation', 'No OCSP Failover to CRL', 'OEM_WHQL_CRYPTO', 'Windows TCB Component', 'DNS Server Trust', 'Windows Third Party Application Component', 'ANY_APPLICATION_POLICY', 'KP_LIFETIME_SIGNING', 'Disallowed List', 'DS_EMAIL_REPLICATION', 'LICENSE_SERVER', 'KP_KEY_RECOVERY', 'Windows Kits Component', 'AUTO_ENROLL_CTL_USAGE', 'PKIX_KP_TIMESTAMP_SIGNING', 'Windows Update', 'Document Encryption', 'KP_CTL_USAGE_SIGNING', 'IPSEC_KP_IKE_INTERMEDIATE', 'PKIX_KP_IPSEC_TUNNEL', 'Code Signing', 'KP_KEY_RECOVERY_AGENT', 'KP_QUALIFIED_SUBORDINATION', 'Early Launch Antimalware Driver', 'Remote Desktop', 'WHQL_CRYPTO', 'EMBEDDED_NT_CRYPTO', 'System Health Authentication', 'DRM', 'PKIX_KP_EMAIL_PROTECTION', 'KP_TIME_STAMP_SIGNING', 'Protected Process Light Verification', 'Endorsement Key Certificate', 'KP_IPSEC_USER', 'PKIX_KP_IPSEC_END_SYSTEM', 'LICENSES', 'Protected Process Verification', 'IdMsKpScLogon', 'HAL Extension', 'KP_OCSP_SIGNING', 'Server Authentication', 'Auto Update End Revocation', 'KP_EFS', 'KP_DOCUMENT_SIGNING', 'Windows Store', 'Kernel Mode Code Signing', 'ENROLLMENT_AGENT', 'ROOT_LIST_SIGNER', 'Windows RT Verification', 'NT5_CRYPTO', 'Revoked List Signer', 'Microsoft Publisher', 'Platform Certificate', ' Windows Software Extension Verification', 'KP_CA_EXCHANGE', 'PKIX_KP_IPSEC_USER', 'Dynamic Code Generator', 'Client Authentication', 'DRM_INDIVIDUALIZATION')]
        [string[]]$ApplicationPolicy,

        [Pki.CATemplate.EnrollmentFlags]$EnrollmentFlags,

        [Pki.CATemplate.PrivateKeyFlags]$PrivateKeyFlags = 0,

        [Pki.CATemplate.KeyUsage]$KeyUsage = 0,

        [int]$Version = 2,

        [timespan]$ValidityPeriod,

        [timespan]$RenewalPeriod,

        [Parameter(Mandatory)]
        [string[]]$SamAccountName,

        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $computer = Get-LabVM -ComputerName $ComputerName
    if (-not $computer)
    {
        Write-Error "The given computer '$ComputerName' could not be found in the lab" -TargetObject $ComputerName
        return
    }

    $variables = Get-Variable -Name KeyUsage, ExtendedKeyUsages, ApplicationPolicies, pkiInternalsTypes, PSBoundParameters
    $functions = Get-Command -Name New-CATemplate, Add-CATemplateStandardPermission, Publish-CATemplate, Get-NextOid, Sync-Parameter, Find-CertificateAuthority

    Invoke-LabCommand -ActivityName "Duplicating CA template $SourceTemplateName -> $TemplateName" -ComputerName $computerName -ScriptBlock {
        Add-Type -TypeDefinition $pkiInternalsTypes

        $p = Sync-Parameter -Command (Get-Command -Name New-CATemplate) -Parameters $ALBoundParameters
        New-CATemplate @p -ErrorVariable e

        if (-not $e)
        {
            $p = Sync-Parameter -Command (Get-Command -Name Add-CATemplateStandardPermission) -Parameters $ALBoundParameters
            Add-CATemplateStandardPermission @p | Out-Null
        }
    } -Variable $variables -Function $functions -PassThru

    Sync-LabActiveDirectory -ComputerName (Get-LabVM -Role RootDC)

    Invoke-LabCommand -ActivityName "Publishing CA template $TemplateName" -ComputerName $ComputerName -ScriptBlock {

        $p = Sync-Parameter -Command (Get-Command -Name Publish-CATemplate, Find-CertificateAuthority) -Parameters $ALBoundParameters
        Publish-CATemplate @p

    } -Function $functions -Variable $variables
}
