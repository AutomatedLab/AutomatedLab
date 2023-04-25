function Get-LabDomainDefinition
{
    Write-LogFunctionEntry

    return $script:lab.Domains

    Write-LogFunctionExit
}
