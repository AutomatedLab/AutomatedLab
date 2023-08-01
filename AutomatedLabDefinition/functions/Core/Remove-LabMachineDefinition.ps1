function Remove-LabMachineDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )

    Write-LogFunctionEntry

    $machine = $script:machines | Where-Object Name -eq $Name

    if (-not $machine)
    {
        Write-ScreenInfo "There is no machine defined with the name '$Name'" -Type Warning
    }
    else
    {
        [Void]$script:machines.Remove($machine)
        Write-PSFMessage "Machine '$Name' removed. Lab has $($Script:machines.Count) machine(s) defined"
    }

    Write-LogFunctionExit
}
