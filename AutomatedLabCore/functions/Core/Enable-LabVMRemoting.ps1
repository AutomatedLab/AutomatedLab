function Enable-LabVMRemoting
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [string[]]$ComputerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName, ParameterSetName = 'All')]
        [switch]$All
    )

    Write-LogFunctionEntry

    if (-not (Get-LabVM))
    {
        Write-Error 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    if ($ComputerName)
    {
        $machines = Get-LabVM -All | Where-Object { $_.Name -in $ComputerName }
    }
    else
    {
        $machines = Get-LabVM -All
    }

    $hypervVMs = $machines | Where-Object HostType -eq 'HyperV'
    if ($hypervVMs)
    {
        Enable-LWHypervVMRemoting -ComputerName $hypervVMs
    }

    $azureVms = $machines | Where-Object HostType -eq 'Azure'
    if ($azureVms)
    {
        Enable-LWAzureVMRemoting -ComputerName $azureVms
    }

    $vmwareVms = $machines | Where-Object HostType -eq 'VmWare'
    if ($vmwareVms)
    {
        Enable-LWVMWareVMRemoting -ComputerName $vmwareVms
    }

    Write-LogFunctionExit
}
