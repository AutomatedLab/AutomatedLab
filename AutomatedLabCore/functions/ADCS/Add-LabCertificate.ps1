function Add-LabCertificate
{

    [cmdletBinding(DefaultParameterSetName = 'ByteArray')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'File')]
        [string]$Path,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByteArray')]
        [byte[]]$RawContentBytes,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.StoreName]$Store,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.CertStoreLocation]$Location,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$ServiceName,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('CER', 'PFX')]
        [string]$CertificateType = 'CER',

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Password = 'AL',

        [Parameter(Mandatory, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName
    )

    begin
    {
        Write-LogFunctionEntry
    }

    process
    {
        $variables = Get-Variable -Name PSBoundParameters

        if ($Path)
        {
            $RawContentBytes = [System.IO.File]::ReadAllBytes($Path)
            $PSBoundParameters.Remove('Path')
            $PSBoundParameters.Add('RawContentBytes', $RawContentBytes)
        }

        Invoke-LabCommand -ActivityName 'Importing Cert file' -ComputerName $ComputerName -ScriptBlock {

            Sync-Parameter -Command (Get-Command -Name Add-Certificate2)
            Add-Certificate2 @ALBoundParameters | Out-Null

        } -Variable $variables -PassThru -NoDisplay

    }

    end
    {
        Write-LogFunctionExit
    }
}
