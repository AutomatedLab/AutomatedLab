function Install-LabFileServers
{
    
    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)

    Write-LogFunctionEntry

    $roleName = [AutomatedLab.Roles]::FileServer

    if (-not (Get-LabVM))
    {
        Write-LogFunctionExitWithError -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first'
        return
    }

    $machines = Get-LabVM | Where-Object { $roleName -in $_.Roles.Name }
    if (-not $machines)
    {
        Write-ScreenInfo -Message "There is no machine with the role '$roleName'" -Type Warning
        Write-LogFunctionExit
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to start up' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 30

    Write-ScreenInfo -Message 'Waiting for File Server role to complete installation' -NoNewLine

    $windowsFeatures = 'FileAndStorage-Services', 'File-Services ', 'FS-FileServer', 'FS-DFS-Namespace', 'FS-Resource-Manager', 'Print-Services', 'NET-Framework-Features', 'NET-Framework-45-Core'
    $remainingMachines = $machines | Where-Object {
        Get-LabWindowsFeature -ComputerName $_ -FeatureName $windowsFeatures -NoDisplay | Where-Object -Property Installed -eq $false
    }

    if ($remainingMachines.Count -eq 0)
    {
        Write-ScreenInfo -Message "...done."
        Write-ScreenInfo -Message "All file servers are already installed."
        return
    }
    
    $jobs = @()
    $jobs += Install-LabWindowsFeature -ComputerName $remainingMachines -FeatureName $windowsFeatures -IncludeManagementTools -AsJob -PassThru -NoDisplay

    Start-LabVM -StartNextMachines 1 -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 30 -NoDisplay
    
    Write-ScreenInfo -Message "Restarting $roleName machines..." -NoNewLine
    Restart-LabVM -ComputerName $remainingMachines -Wait -NoNewLine
    Write-ScreenInfo -Message done.

    if ($CreateCheckPoints)
    {
        Checkpoint-LabVM -ComputerName $remainingMachines -SnapshotName "Post '$roleName' Installation"
    }

    Write-LogFunctionExit
}
