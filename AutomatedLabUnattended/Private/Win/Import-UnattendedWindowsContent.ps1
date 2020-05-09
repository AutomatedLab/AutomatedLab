function Import-UnattendedWindowsContent
{
    param
    (
        [Parameter(Mandatory = $true)]
        [xml]
        $Content
    )

    $script:un = $Content
    $script:ns = @{ un = 'urn:schemas-microsoft-com:unattend' }
    $Script:wcmNamespaceUrl = 'http://schemas.microsoft.com/WMIConfig/2002/State'
}