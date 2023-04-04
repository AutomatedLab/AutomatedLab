function Set-LabVMUacStatus
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [bool]$EnableLUA,

        [int]$ConsentPromptBehaviorAdmin,

        [int]$ConsentPromptBehaviorUser,

        [switch]$PassThru
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName

    if (-not $machines)
    {
        Write-Error 'The given machines could not be found'
        return
    }

    $functions = Get-Command -Name Get-VMUacStatus, Set-VMUacStatus, Sync-Parameter
    $variables = Get-Variable -Name PSBoundParameters
    $result = Invoke-LabCommand -ActivityName 'Set Uac Status' -ComputerName $machines -ScriptBlock {

        Sync-Parameter -Command (Get-Command -Name Set-VMUacStatus)
        Set-VMUacStatus @ALBoundParameters

    } -Function $functions -Variable $variables -PassThru

    if ($result.UacStatusChanged)
    {
        Write-ScreenInfo "The change requires a reboot of '$ComputerName'." -Type Warning
    }

    if ($PassThru)
    {
        Get-LabMachineUacStatus -ComputerName $ComputerName
    }

    Write-LogFunctionExit
}
