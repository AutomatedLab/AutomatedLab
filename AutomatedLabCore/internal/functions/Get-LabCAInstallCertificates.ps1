function Get-LabCAInstallCertificates
{

    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [AutomatedLab.Machine[]]$Machines
    )

    begin
    {
        Write-LogFunctionEntry

        if (-not (Test-Path -Path "$((Get-Lab).LabPath)\Certificates"))
        {
            New-Item -Path "$((Get-Lab).LabPath)\Certificates" -ItemType Directory | Out-Null
        }
    }

    process
    {
        #Get all certificates from CA servers and place temporalily on host machine
        foreach ($machine in $machines)
        {
            $sourceFile = Invoke-LabCommand -ComputerName $machine -ScriptBlock {
                (Get-Item -Path 'C:\Windows\System32\CertSrv\CertEnroll\*.crt' |
                    Sort-Object -Property LastWritten -Descending |
                Select-Object -First 1).FullName
            } -PassThru -NoDisplay

            $tempDestination = "$((Get-Lab).LabPath)\Certificates\$($Machine).crt"

            $caSession = New-LabPSSession -ComputerName $machine.Name
            Receive-File -Source $sourceFile -Destination $tempDestination -Session $caSession
        }
    }

    end
    {
        Write-LogFunctionExit
    }

}
