Add-Type -Path $PSScriptRoot\AutomatedLab.dll

if ((Get-Module -ListAvailable Ships) -and (Get-Module -ListAvailable AutomatedLab.Ships))
{
    Import-Module Ships,AutomatedLab.Ships
    [void] (New-PSDrive -PSProvider SHiPS -Name Labs -Root "AutomatedLab.Ships#LabHost" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue)
}

$callingCallFrame = (Get-PSCallStack)[1]
if ($callingCallFrame.ScriptName -like '*AutomatedLab.init.ps1*' -or
$callingCallFrame.ScriptName -like '*AutomatedLab.psm1*')
{
    return
}


$dynamicLabSources = New-Object AutomatedLab.DynamicVariable 'global:labSources', { Get-LabSourcesLocationInternal }, { $null }
$executioncontext.SessionState.PSVariable.Set($dynamicLabSources)

Register-ArgumentCompleter -CommandName Add-LabMachineDefinition -ParameterName OperatingSystem -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-LabAvailableOperatingSystem -Path $labSources\ISOs -UseOnlyCache |
    Where-Object { ($_.ProductKey -or $_.OperatingSystemType -eq 'Linux') -and $_.OperatingSystemName -like "*$wordToComplete*" } |
    Group-Object -Property OperatingSystemName |
    ForEach-Object { $_.Group | Sort-Object -Property Version -Descending | Select-Object -First 1 } |
    Sort-Object -Property OperatingSystemName |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new("'$($_.OperatingSystemName)'", "'$($_.OperatingSystemName)'", 'ParameterValue', "$($_.Version) $($_.OperatingSystemName)")
    }
}

Register-ArgumentCompleter -CommandName Import-Lab, Remove-Lab -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    $path = "$([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData))\AutomatedLab\Labs"
    Get-ChildItem -Path $path -Directory |
    ForEach-Object {
        if ($_.Name -contains ' ')
        {
            [System.Management.Automation.CompletionResult]::new("'$($_.Name)'", "'$($_.Name)'", 'ParameterValue', $_.Name)
        }
        else
        {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
        }
    }
}

$commands = Get-Command -Module AutomatedLab*, PSFileTransfer | Where-Object { $_.Parameters.ContainsKey('ComputerName') }
Register-ArgumentCompleter -CommandName $commands -ParameterName ComputerName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    Get-LabVM -All -IncludeLinux |
    ForEach-Object {
        if ($_.Roles)
        {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Roles)
        }
        else
        {
            [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
        }
    }
}

Register-ArgumentCompleter -CommandName Add-LabMachineDefinition -ParameterName DomainName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    (Get-LabDefinition).Domains |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
    }
}

Register-ArgumentCompleter -CommandName Add-LabMachineDefinition -ParameterName Roles -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

    [System.Enum]::GetNames([AutomatedLab.Roles]) |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

#importing the module results in calling the following code multiple times due to module import recursion
#the following line makes sure that the following code runs only once when called from an external source
if (((Get-PSCallStack)[1].Location -notlike 'AutomatedLab*.psm1*'))
{
    Get-LabAvailableOperatingSystem -Path $labSources\ISOs -NoDisplay | Out-Null
}

#download the ProductKeys.xml file if it does not exist. The installer puts the file into 'C:\ProgramData\AutomatedLab\Assets'
#but when installing AL using the PowerShell Gallery, this file is missing.
$productKeyFileLink = Get-LabConfigurationItem -Name ProductKeyFileLink
$productKeyFileName = Get-LabConfigurationItem -Name ProductKeyFileName
$productKeyFilePath = Join-Path -Path C:\ProgramData\AutomatedLab\Assets -ChildPath $productKeyFileName

if (-not (Test-Path -Path 'C:\ProgramData\AutomatedLab\Assets'))
{
    New-Item -Path C:\ProgramData\AutomatedLab\Assets -ItemType Directory | Out-Null
}

if (-not (Test-Path -Path $productKeyFilePath))
{
    Get-LabInternetFile -Uri $productKeyFileLink -Path $productKeyFilePath
}

$productKeyCustomFileName = Get-LabConfigurationItem -Name ProductKeyCustomFileName
$productKeyCustomFilePath = Join-Path -Path C:\ProgramData\AutomatedLab\Assets -ChildPath $productKeyCustomFileName

if (-not (Test-Path -Path $productKeyCustomFilePath))
{
    $store = New-Object 'AutomatedLab.ListXmlStore[AutomatedLab.ProductKey]'
    
    $dummyProductKey = New-Object AutomatedLab.ProductKey -Property @{ Key = '123'; OperatingSystemName = 'OS'; Version = '1.0' }
    $store.Add($dummyProductKey)
    $store.Export($productKeyCustomFilePath)
}
