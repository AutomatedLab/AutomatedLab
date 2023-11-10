function Set-LabVMDescription
{

    [CmdletBinding()]
    param (
        [hashtable]$Hashtable,

        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $t = Get-Type -GenericType AutomatedLab.SerializableDictionary -T String, String
    $d = New-Object $t

    foreach ($kvp in $Hashtable.GetEnumerator())
    {
        $d.Add($kvp.Key, $kvp.Value)
    }

    $sb = New-Object System.Text.StringBuilder
    $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
    $xmlWriterSettings.ConformanceLevel = 'Auto'
    $xmlWriter = [System.Xml.XmlWriter]::Create($sb, $xmlWriterSettings)

    $d.WriteXml($xmlWriter)

    Get-LWHypervVm -Name $ComputerName -ErrorAction SilentlyContinue | Hyper-V\Set-VM -Notes $sb.ToString()

    Write-LogFunctionExit
}
