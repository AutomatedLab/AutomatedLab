function Get-LabVirtualNetworkDefinition
{
    [CmdletBinding()]
    [OutputType([AutomatedLab.VirtualNetwork])]
    param(
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ByAddressSpace')]
        [string]$AddressSpace
    )

    $script:lab = Get-LabDefinition -ErrorAction SilentlyContinue

    Write-LogFunctionEntry

    if ($PSCmdlet.ParameterSetName -eq 'ByAddressSpace')
    {
        return $script:lab.VirtualNetworks | Where-Object AddressSpace -eq $AddressSpace
    }
    else
    {
        if ($Name)
        {
            return $script:lab.VirtualNetworks | Where-Object Name -eq $Name
        }
        else
        {
            return $script:lab.VirtualNetworks
        }
    }

    Write-LogFunctionExit
}
