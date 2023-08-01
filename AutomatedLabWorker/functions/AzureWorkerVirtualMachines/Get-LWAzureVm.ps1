function Get-LWAzureVm
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$ComputerName
    )

    Test-LabHostConnected -Throw -Quiet

    #required to suporess verbose messages, warnings and errors
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-LogFunctionEntry

    $azureRetryCount = Get-LabConfigurationItem -Name AzureRetryCount

    $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue -ErrorVariable getazvmerror
    $count = 1
    while (-not $azureVms -and $count -le $azureRetryCount)
    {
        Write-ScreenInfo -Type Verbose -Message "Get-AzVM did not return anything, attempt $count of $($azureRetryCount) attempts. Azure presented us with the error: $($getazvmerror.Exception.Message)"
        Start-Sleep -Seconds 2
        $azureVms = Get-AzVM -Status -ResourceGroupName (Get-LabAzureDefaultResourceGroup).ResourceGroupName -ErrorAction SilentlyContinue -ErrorVariable getazvmerror
        $count++
    }

    if (-not $azureVms)
    {
        Write-ScreenInfo -Message "Get-AzVM did not return anything in $($azureRetryCount) attempts, stopping lab deployment. Azure presented us with the error: $($getazvmerror.Exception.Message)"
        throw "Get-AzVM did not return anything in $($azureRetryCount) attempts, stopping lab deployment. Azure presented us with the error: $($getazvmerror.Exception.Message)"
    }

    if ($ComputerName.Count -eq 0) { return $azureVms }
    $azureVms | Where-Object Name -in $ComputerName
}
