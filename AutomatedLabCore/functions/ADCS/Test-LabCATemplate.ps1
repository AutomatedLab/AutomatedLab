function Test-LabCATemplate
{

    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,

        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    Write-LogFunctionEntry

    $computer = Get-LabVM -ComputerName $ComputerName
    if (-not $computer)
    {
        Write-Error "The given computer '$ComputerName' could not be found in the lab" -TargetObject $ComputerName
        return
    }

    $variables = Get-Variable -Name PSBoundParameters
    $functions = Get-Command -Name Test-CATemplate, Sync-Parameter

    Invoke-LabCommand -ActivityName "Testing template $TemplateName" -ComputerName $ComputerName -ScriptBlock {

        $p = Sync-Parameter -Command (Get-Command -Name Test-CATemplate) -Parameters $ALBoundParameters
        Test-CATemplate @p

    } -Function $functions -Variable $variables -PassThru -NoDisplay
}
