function Get-LWHypervVMDescription
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry
    
    $notePath = Join-Path -Path (Get-Lab).LabPath -ChildPath "$ComputerName.xml"
    $type = Get-Type -GenericType AutomatedLab.DictionaryXmlStore -T string, string

    if (-not (Test-Path $notePath))
    {
        # Old labs still use the previous, slow method
        $vm = Get-LWHypervVM -Name $ComputerName -ErrorAction SilentlyContinue
        if (-not $vm)
        {
            return
        }

        $prefix = '#AL<#'
        $suffix = '#>AL#'
        $pattern = '{0}(?<ALNotes>[\s\S]+){1}' -f [regex]::Escape($prefix), [regex]::Escape($suffix)

        $notes = if ($vm.Notes -match $pattern) {
            $Matches.ALNotes
        }
        else {
            $vm.Notes
        }

        try
        {
            $dictionary = New-Object $type
            $importMethodInfo = $type.GetMethod('ImportFromString', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
            $dictionary = $importMethodInfo.Invoke($null, $notes.Trim())
            return $dictionary
        }
        catch
        {
            Write-ScreenInfo -Message "The notes field of the virtual machine '$ComputerName' could not be read as XML" -Type Warning
            return
        }
    }

    $dictionary = New-Object $type
    try
    {
        $importMethodInfo = $type.GetMethod('Import', [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Static)
        $dictionary = $importMethodInfo.Invoke($null, $notePath)
        $dictionary
    }
    catch
    {
        Write-ScreenInfo -Message "The notes field of the virtual machine '$ComputerName' could not be read as XML" -Type Warning
    }

    Write-LogFunctionExit
}
