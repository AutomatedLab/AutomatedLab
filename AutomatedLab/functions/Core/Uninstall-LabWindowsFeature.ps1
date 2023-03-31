function Uninstall-LabWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName,

        [switch]$IncludeManagementTools,

        [switch]$UseLocalCredential,

        [int]$ProgressIndicator = 5,

        [switch]$NoDisplay,

        [switch]$PassThru,

        [switch]$AsJob
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName
    if (-not $machines)
    {
        Write-LogFunctionExitWithError -Message 'The specified machines could not be found'
        return
    }
    if ($machines.Count -ne $ComputerName.Count)
    {
        $machinesNotFound = Compare-Object -ReferenceObject $ComputerName -DifferenceObject ($machines.Name)
        Write-ScreenInfo "The specified machines $($machinesNotFound.InputObject -join ', ') could not be found" -Type Warning
    }

    Write-ScreenInfo -Message "Uninstalling Windows Feature(s) '$($FeatureName -join ', ')' on computer(s) '$($ComputerName -join ', ')'" -TaskStart

    if ($AsJob)
    {
        Write-ScreenInfo -Message 'Windows Feature(s) is being uninstalled in the background' -TaskEnd
    }

    $stoppedMachines = (Get-LabVMStatus -ComputerName $ComputerName -AsHashTable).GetEnumerator() | Where-Object Value -eq Stopped
    if ($stoppedMachines)
    {
        Start-LabVM -ComputerName $stoppedMachines.Name -Wait
    }

    $hyperVMachines = Get-LabVM -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'HyperV'}
    $azureMachines = Get-LabVM -ComputerName $ComputerName | Where-Object {$_.HostType -eq 'Azure'}

    if ($hyperVMachines)
    {
        $jobs = Uninstall-LWHypervWindowsFeature -Machine $hyperVMachines -FeatureName $FeatureName -UseLocalCredential:$UseLocalCredential -IncludeManagementTools:$IncludeManagementTools -AsJob:$AsJob -PassThru:$PassThru
    }
    elseif ($azureMachines)
    {
        $jobs = Uninstall-LWAzureWindowsFeature -Machine $azureMachines -FeatureName $FeatureName -UseLocalCredential:$UseLocalCredential -IncludeManagementTools:$IncludeManagementTools -AsJob:$AsJob -PassThru:$PassThru
    }

    if (-not $AsJob)
    {
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }

    if ($PassThru)
    {
        $jobs
    }

    Write-LogFunctionExit
}
