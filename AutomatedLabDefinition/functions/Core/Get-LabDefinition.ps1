function Get-LabDefinition
{
    [CmdletBinding()]
    [OutputType([AutomatedLab.Lab])]
    param ()

    Write-LogFunctionEntry

    return $script:lab

    Write-LogFunctionExit
}
