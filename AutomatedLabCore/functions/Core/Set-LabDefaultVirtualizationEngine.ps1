function Set-LabDefaultVirtualizationEngine
{
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateSet('Azure', 'HyperV', 'VMware')]
        [string]$VirtualizationEngine
    )

    if (Get-LabDefinition)
    {
        (Get-LabDefinition).DefaultVirtualizationEngine = $VirtualizationEngine
    }
    else
    {
        throw 'No lab defined. Please call New-LabDefinition first before calling Set-LabDefaultOperatingSystem.'
    }
}
