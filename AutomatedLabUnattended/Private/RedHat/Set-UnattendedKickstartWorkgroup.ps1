function Set-UnattendedKickstartWorkgroup
{
    param 
    (
		[Parameter(Mandatory = $true)]
        [string]
        $WorkgroupName
    )
    
    $script:un += 'auth --smbworkgroup={0}' -f $WorkgroupName
}