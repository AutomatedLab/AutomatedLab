function Get-LabWindowsFeature
{
    [cmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [ValidateNotNullOrEmpty()]
        [string[]]$FeatureName = '*',

        [switch]$UseLocalCredential,

        [int]$ProgressIndicator = 5,

        [switch]$NoDisplay,

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

    Write-ScreenInfo -Message "Getting Windows Feature(s) '$($FeatureName -join ', ')' on computer(s) '$($ComputerName -join ', ')'" -TaskStart

    if ($AsJob)
    {
        Write-ScreenInfo -Message 'Getting Windows Feature(s) in the background' -TaskEnd
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
        $params = @{
            Machine            = $hyperVMachines
            FeatureName        = $FeatureName
            UseLocalCredential = $UseLocalCredential
            AsJob              = $AsJob
        }

        $result = Get-LWHypervWindowsFeature @params
    }
    elseif ($azureMachines)
    {
        $params = @{
            Machine            = $azureMachines
            FeatureName        = $FeatureName
            UseLocalCredential = $UseLocalCredential
            AsJob              = $AsJob
        }

        $result = Get-LWAzureWindowsFeature @params
    }

    $result

    if (-not $AsJob)
    {
        Write-ScreenInfo -Message 'Done' -TaskEnd
    }
    Write-LogFunctionExit
}
