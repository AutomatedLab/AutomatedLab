function Install-LabWebServers
{
    [cmdletBinding()]
    param ([switch]$CreateCheckPoints)

    Write-LogFunctionEntry

    $roleName = [AutomatedLab.Roles]::WebServer

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

    Write-ScreenInfo -Message 'Waiting for Web Server role to complete installation' -NoNewLine

    $coreMachines    = $machines | Where-Object { $_.OperatingSystem.Installation -match 'Core' }
    $nonCoreMachines = $machines | Where-Object { $_.OperatingSystem.Installation -notmatch 'Core' }

    $jobs = @()
    if ($coreMachines)    { $jobs += Install-LabWindowsFeature -ComputerName $coreMachines    -AsJob -PassThru -NoDisplay -IncludeAllSubFeature -FeatureName Web-WebServer, Web-Application-Proxy, Web-Health, Web-Performance, Web-Security, Web-App-Dev, Web-Ftp-Server, Web-Metabase, Web-Lgcy-Scripting, Web-WMI, Web-Scripting-Tools, Web-Mgmt-Service, Web-WHC }
    if ($nonCoreMachines) { $jobs += Install-LabWindowsFeature -ComputerName $nonCoreMachines -AsJob -PassThru -NoDisplay -IncludeAllSubFeature -FeatureName Web-Server }

    Start-LabVm -StartNextMachines 1 -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 30 -NoDisplay

    if ($CreateCheckPoints)
    {
        Checkpoint-LabVM -ComputerName $machines -SnapshotName 'Post Web Installation'
    }

    Write-LogFunctionExit
}
