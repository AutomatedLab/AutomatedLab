function Get-LabVMStatus
{
    [CmdletBinding()]
    param (
        [string[]]$ComputerName,

        [switch]$AsHashTable
    )

    Write-LogFunctionEntry

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if ($ComputerName)
    {
        $vms = Get-LabVM -ComputerName $ComputerName -IncludeLinux | Where-Object { -not $_.SkipDeployment }
    }
    else
    {
        $vms = Get-LabVM -IncludeLinux
    }

    $vms = $vms | Where-Object SkipDeployment -eq $false

    $hypervVMs = $vms | Where-Object HostType -eq 'HyperV'
    if ($hypervVMs) { $hypervStatus = Get-LWHypervVMStatus -ComputerName $hypervVMs.ResourceName }

    $azureVMs = $vms | Where-Object HostType -eq 'Azure'
    if ($azureVMs) { $azureStatus = Get-LWAzureVMStatus -ComputerName $azureVMs.ResourceName }

    $vmwareVMs = $vms | Where-Object HostType -eq 'VMWare'
    if ($vmwareVMs) { $vmwareStatus = Get-LWVMWareVMStatus -ComputerName $vmwareVMs.ResourceName }

    $result = @{ }
    if ($hypervStatus) { $result = $result + $hypervStatus }
    if ($azureStatus) { $result = $result + $azureStatus }
    if ($vmwareStatus) { $result = $result + $vmwareStatus }

    if ($result.Count -eq 1 -and -not $AsHashTable)
    {
        $result.Values[0]
    }
    else
    {
        $result
    }

    Write-LogFunctionExit
}
