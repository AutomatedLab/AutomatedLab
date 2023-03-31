function Remove-LabVirtualNetworkDefinition
{


    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Name
    )

    Write-LogFunctionEntry

    foreach ($n in $Name)
    {
        $network = $script:lab.VirtualNetworks | Where-Object Name -eq $n

        if (-not $network)
        {
            Write-ScreenInfo "There is no network defined with the name '$n'" -Type Warning
        }
        else
        {
            [Void]$script:lab.VirtualNetworks.Remove($network)
            Write-PSFMessage "Network '$n' removed. Lab has $($Script:lab.VirtualNetworks.Count) network(s) defined"
        }
    }

    Write-LogFunctionExit
}
