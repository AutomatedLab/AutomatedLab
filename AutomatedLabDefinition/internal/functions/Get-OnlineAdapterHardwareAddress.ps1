function Get-OnlineAdapterHardwareAddress
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Special handling for Linux")]
    [OutputType([string[]])]
    [CmdletBinding()]
    param ( )

    if ($IsLinux)
    {
        ip link show up | ForEach-Object { if ($_ -match '(\w{2}:?){6}' -and $Matches.0 -ne '00:00:00:00:00:00')
            {
                $Matches.0
            }
        }
    }
    else
    {
        Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled -and $_.NetConnectionID } | Select-Object -ExpandProperty MacAddress
    }
}
