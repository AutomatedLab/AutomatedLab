function Clear-LabCache
{
    [cmdletBinding()]

    param()

    Write-LogFunctionEntry

    if ($IsLinux -or $IsMacOs)
    {
        $storePath = Join-Path -Path (Get-LabConfigurationItem -Name LabAppDataRoot) -ChildPath 'Stores'
        Get-ChildItem -Path $storePath -Filter *.xml | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    else
    {
        Remove-Item -Path Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Software\AutomatedLab\Cache -Force -ErrorAction SilentlyContinue
    }
    Write-PSFMessage 'AutomatedLab cache removed'

    Write-LogFunctionExit
}
