function Set-UnattendedKickstartWorkgroup
{
    param
    (
		[Parameter(Mandatory = $true)]
        [string]
        $WorkgroupName
    )

    $script:un.Add(('auth --smbworkgroup={0}' -f $WorkgroupName))
}
