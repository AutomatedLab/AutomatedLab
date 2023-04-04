function Get-LabVMDotNetFrameworkVersion
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [switch]$NoDisplay
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName

    if (-not $machines)
    {
        Write-Error 'The given machines could not be found'
        return
    }

    Invoke-LabCommand -ActivityName 'Get .net Framework version' -ComputerName $machines -ScriptBlock {
        Get-DotNetFrameworkVersion
    } -Function (Get-Command -Name Get-DotNetFrameworkVersion) -PassThru -NoDisplay:$NoDisplay

    Write-LogFunctionExit
}
