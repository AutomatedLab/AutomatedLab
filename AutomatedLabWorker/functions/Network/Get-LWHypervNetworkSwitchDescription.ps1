function Get-LWHypervNetworkSwitchDescription
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$NetworkSwitchName
    )

    Write-LogFunctionEntry

    if (-not (Get-Lab -ErrorAction SilentlyContinue))
    {
        return
    }
    
    $notePath = Join-Path -Path (Get-Lab).LabPath -ChildPath "Network_$NetworkSwitchName.xml"
    if (-not (Test-Path -Path $notePath))
    {
        Write-Error "The file '$notePath' did not exist. Cannot import metadata of network switch '$NetworkSwitchName'"
        return
    }
    
    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T string, string

    $dictionary = New-Object $type
    try
    {
        $importMethodInfo = $type.GetMethod('Import', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
        $dictionary = $importMethodInfo.Invoke($null, $notePath)
        $dictionary
    }
    catch
    {
        Write-ScreenInfo -Message "The metadata of the network switch '$ComputerName' could not be read as XML" -Type Warning
    }

    Write-LogFunctionExit
}
