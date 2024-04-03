function Set-UnattendedCloudInitComputerName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ComputerName
    )

    $Script:un['autoinstall']['user-data']['hostname'] = $ComputerName.ToLower()
}
