$moduleroot = (Get-Module -List AutomatedLab)[0].ModuleBAse
if ($PSEdition -eq 'Core')
{
	Add-Type -Path $moduleroot\lib\core\AutomatedLab.dll
}
else
{
	Add-Type -Path $moduleroot\lib\full\AutomatedLab.dll
}
