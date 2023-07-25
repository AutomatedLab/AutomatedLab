function Set-UnattendedCloudInitComputerName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName
    )

    $Script:un['user-data']['hostname'] = $ComputerName
}
