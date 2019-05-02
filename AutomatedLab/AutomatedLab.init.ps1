if ($PSEdition -eq 'Core')
{
	Add-Type -Path $PSScriptRoot\lib\core\AutomatedLab.dll
}
else
{
	Add-Type -Path $PSScriptRoot\lib\full\AutomatedLab.dll
}

if ((Get-Module -ListAvailable Ships) -and (Get-Module -ListAvailable AutomatedLab.Ships))
{
    Import-Module Ships,AutomatedLab.Ships
    [void] (New-PSDrive -PSProvider SHiPS -Name Labs -Root "AutomatedLab.Ships#LabHost" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
}

Set-Item -Path Env:\SuppressAzurePowerShellBreakingChangeWarning -Value true