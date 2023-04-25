function Get-LabVMUacStatus
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName

    if (-not $machines)
    {
        Write-Error 'The given machines could not be found'
        return
    }

    Invoke-LabCommand -ActivityName 'Get Uac Status' -ComputerName $machines -ScriptBlock {
        Get-VMUacStatus
    } -Function (Get-Command -Name Get-VMUacStatus) -PassThru

    Write-LogFunctionExit
}
