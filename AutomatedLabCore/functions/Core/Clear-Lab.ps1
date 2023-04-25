function Clear-Lab
{
    [cmdletBinding()]

    param ()

    Write-LogFunctionEntry

    $Script:data = $null
    foreach ($module in $MyInvocation.MyCommand.Module.NestedModules | Where-Object ModuleType -eq 'Script')
    {
        & $module { $Script:data = $null }
    }

    Write-LogFunctionExit
}
