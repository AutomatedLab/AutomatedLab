function Sync-LabActiveDirectory
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string[]]$ComputerName,

        [int]$ProgressIndicator,

        [switch]$AsJob,

        [switch]$Passthru
    )

    Write-LogFunctionEntry

    $machines = Get-LabVM -ComputerName $ComputerName
    $lab = Get-Lab

    if (-not $machines)
    {
        Write-Error "The machine '$ComputerName' could not be found in the current lab"
        return
    }

    foreach ($machine in $machines)
    {
        if (-not $machine.DomainName)
        {
            Write-PSFMessage -Message 'The machine is not domain joined hence AD replication cannot be triggered'
            return
        }

        #region Force Replication Scriptblock
        $adForceReplication = {
            $VerbosePreference = $using:VerbosePreference

            ipconfig.exe -flushdns

            if (-not -(Test-Path -Path C:\DeployDebug))
            {
                New-Item C:\DeployDebug -Force -ItemType Directory | Out-Null
            }

            Write-Verbose -Message 'Getting list of DCs'
            $dcs = repadmin.exe /viewlist *
            Write-Verbose -Message "List: '$($dcs -join ', ')'"
            (Get-Date -Format 'yyyy-MM-dd hh:mm:ss') | Add-Content -Path c:\DeployDebug\DCList.log -Force
            $dcs | Add-Content -Path c:\DeployDebug\DCList.log

            foreach ($dc in $dcs)
            {
                if ($dc)
                {
                    $dcName = $dc.Split()[2]
                    Write-Verbose -Message "Executing 'repadmin.exe /SyncAll /Ae $dcname'"
                    $result = repadmin.exe /SyncAll /Ae $dcName
                    (Get-Date -Format 'yyyy-MM-dd hh:mm:ss') | Add-Content -Path "c:\DeployDebug\Syncs-$($dcName).log" -Force
                    $result | Add-Content -Path "c:\DeployDebug\Syncs-$($dcName).log"
                }
            }
            Write-Verbose -Message "Executing 'repadmin.exe /ReplSum'"
            $result = repadmin.exe /ReplSum
            $result | Add-Content -Path c:\DeployDebug\repadmin.exeResult.log

            Restart-Service -Name DNS -WarningAction SilentlyContinue

            ipconfig.exe /registerdns

            Write-Verbose -Message 'Getting list of DCs'
            $dcs = repadmin.exe /viewlist *
            Write-Verbose -Message "List: '$($dcs -join ', ')'"
            (Get-Date -Format 'yyyy-MM-dd hh:mm:ss') | Add-Content -Path c:\DeployDebug\DCList.log -Force
            $dcs | Add-Content -Path c:\DeployDebug\DCList.log
            foreach ($dc in $dcs)
            {
                if ($dc)
                {
                    $dcName = $dc.Split()[2]
                    Write-Verbose -Message "Executing 'repadmin.exe /SyncAll /Ae $dcname'"
                    $result = repadmin.exe /SyncAll /Ae $dcName
                    (Get-Date -Format 'yyyy-MM-dd hh:mm:ss') | Add-Content -Path "c:\DeployDebug\Syncs-$($dcName).log" -Force
                    $result | Add-Content -Path "c:\DeployDebug\Syncs-$($dcName).log"
                }
            }
            Write-Verbose -Message "Executing 'repadmin.exe /ReplSum'"
            $result = repadmin.exe /ReplSum
            $result | Add-Content -Path c:\DeployDebug\repadmin.exeResult.log

            ipconfig.exe /registerdns

            Restart-Service -Name DNS -WarningAction SilentlyContinue

            #for debugging
            #dnscmd /zoneexport $env:USERDNSDOMAIN "c:\DeployDebug\$($env:USERDNSDOMAIN).txt"
        }
        #endregion Force Replication Scriptblock

        Invoke-LabCommand -ActivityName "Performing ipconfig /registerdns on '$ComputerName'" `
        -ComputerName $ComputerName -ScriptBlock { ipconfig.exe /registerdns } -NoDisplay

        if ($AsJob)
        {
            $job = Invoke-LabCommand -ActivityName "Triggering replication on '$ComputerName'" -ComputerName $ComputerName -ScriptBlock $adForceReplication -AsJob -Passthru -NoDisplay

            if ($PassThru)
            {
                $job
            }
        }
        else
        {
            $result = Invoke-LabCommand -ActivityName "Triggering replication on '$ComputerName'" -ComputerName $ComputerName -ScriptBlock $adForceReplication -Passthru -NoDisplay

            if ($PassThru)
            {
                $result
            }
        }
    }

    Write-LogFunctionExit
}
