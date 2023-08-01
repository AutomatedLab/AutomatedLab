function Get-LabCertificate
{

    [cmdletBinding(DefaultParameterSetName = 'FindCer')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'FindCer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'FindPfx')]
        [string]$SearchString,

        [Parameter(Mandatory = $true, ParameterSetName = 'FindCer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'FindPfx')]
        [System.Security.Cryptography.X509Certificates.X509FindType]$FindType,

        [Parameter(ParameterSetName = 'AllCer')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [Parameter(ParameterSetName = 'FindCer')]
        [Parameter(ParameterSetName = 'FindPfx')]
        [System.Security.Cryptography.X509Certificates.CertStoreLocation]$Location,

        [Parameter(ParameterSetName = 'AllCer')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [Parameter(ParameterSetName = 'FindCer')]
        [Parameter(ParameterSetName = 'FindPfx')]
        [System.Security.Cryptography.X509Certificates.StoreName]$Store,

        [Parameter(ParameterSetName = 'AllCer')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [Parameter(ParameterSetName = 'FindCer')]
        [Parameter(ParameterSetName = 'FindPfx')]
        [string]$ServiceName,

        [Parameter(Mandatory = $true, ParameterSetName = 'AllCer')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AllPfx')]
        [switch]$All,

        [Parameter(ParameterSetName = 'AllCer')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [switch]$IncludeServices,

        [Parameter(Mandatory = $true, ParameterSetName = 'FindPfx')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AllPfx')]
        [securestring]$Password = ('AL' | ConvertTo-SecureString -AsPlainText -Force),

        [Parameter(ParameterSetName = 'FindPfx')]
        [Parameter(ParameterSetName = 'AllPfx')]
        [switch]$ExportPrivateKey,

        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $variables = Get-Variable -Name PSBoundParameters

    foreach ($computer in $ComputerName)
    {
        Invoke-LabCommand -ActivityName 'Exporting certificates' -ComputerName $ComputerName -ScriptBlock {
            Sync-Parameter -Command (Get-Command -Name Get-Certificate2)
            Get-Certificate2 @ALBoundParameters

        } -Variable $variables -PassThru -NoDisplay
    }

    Write-LogFunctionExit
}
