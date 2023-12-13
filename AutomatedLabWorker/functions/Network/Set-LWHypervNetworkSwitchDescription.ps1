function Set-LWHypervNetworkSwitchDescription
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]$Hashtable,

        [Parameter(Mandatory)]
        [string]$NetworkSwitchName
    )

    Write-LogFunctionEntry

    $notePath = Join-Path -Path (Get-Lab).LabPath -ChildPath "Network_$NetworkSwitchName.xml"

    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T string, string
    $dictionary = New-Object $type

    foreach ($kvp in $Hashtable.GetEnumerator())
    {
        $dictionary.Add($kvp.Key, $kvp.Value)
    }

    $dictionary.Export($notePath)

    Write-LogFunctionExit
}
