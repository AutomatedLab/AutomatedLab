function Get-LabHyperVAvailableMemory
{
    # .ExternalHelp AutomatedLab.Help.xml
    if ($IsLinux -or $IsMacOS)
    {
        return [int]((Get-Content -Path /proc/meminfo) -replace ':', '=' -replace '\skB' | ConvertFrom-StringData).MemTotal
    }

    [int](((Get-CimInstance -Namespace Root\Cimv2 -Class win32_operatingsystem).TotalVisibleMemorySize) / 1kb)
}
