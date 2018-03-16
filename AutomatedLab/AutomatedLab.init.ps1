function Get-ALTypeComplete_AvailableLabs
{
    $path = "$([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData))\AutomatedLab\Labs"
    Get-ChildItem -Path $path -Directory
}

function Get-ALTypeComplete_LabVMs
{
    (Get-LabVM -All -IncludeLinux).Name
}

function Get-ALTypeComplete_DiskName
{
    (Get-Lab).Disks.Name
}

function Get-ALTypeComplete_DomainName
{
    (Get-Lab).Domains.Name
}

function Get-ALTypeComplete_OperatingSystemName
{
    (Get-LabAvailableOperatingSystem -Path $global:labSources).OperatingSystemName
}

Register-ArgumentCompleter -CommandName Import-Lab, Remove-Lab -ParameterName Name -ScriptBlock (Get-Command -Name Get-ALTypeComplete_AvailableLabs).ScriptBlock

$commands = Get-Command -Module AutomatedLab, PSFileTransfer | Where-Object { $_.Parameters.ContainsKey('ComputerName') }
Register-ArgumentCompleter -CommandName $commands -ParameterName ComputerName -ScriptBlock (Get-Command -Name Get-ALTypeComplete_LabVMs).ScriptBlock

Register-ArgumentCompleter -CommandName Add-LabMachineDefinition -ParameterName DiskName -ScriptBlock (Get-Command -Name Get-ALTypeComplete_DiskName).ScriptBlock
Register-ArgumentCompleter -CommandName Add-LabMachineDefinition -ParameterName OperatingSystem -ScriptBlock (Get-Command -Name Get-ALTypeComplete_OperatingSystemName).ScriptBlock
Register-ArgumentCompleter -CommandName Add-LabMachineDefinition -ParameterName DomainName -ScriptBlock (Get-Command -Name Get-ALTypeComplete_DomainName).ScriptBlock

Add-Type -Path $PSScriptRoot\AutomatedLab.dll