function Update-LabVMWareSettings
{
	if ((Get-PSCallStack).Command -contains 'Import-Lab')
	{
		$Script:lab = Get-Lab
	}
	elseif ((Get-PSCallStack).Command -contains 'Add-LabVMWareSettings')
	{
		$Script:lab = Get-LabDefinition
	}
}
