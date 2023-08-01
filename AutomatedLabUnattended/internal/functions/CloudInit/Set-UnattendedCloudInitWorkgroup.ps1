function Set-UnattendedCloudInitWorkgroup
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]$WorkgroupName
	)
    
	$script:un['late-commands'] += "sed -i 's|[#]*workgroup = WORKGROUP|workgroup = {0}|g' /etc/samba/smb.conf" -f $WorkgroupName
}
