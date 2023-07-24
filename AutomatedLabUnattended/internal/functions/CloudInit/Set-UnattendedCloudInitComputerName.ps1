function Set-UnattendedCloudInitComputerName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName
    )

    $Script:un.hostname = $ComputerName
}
