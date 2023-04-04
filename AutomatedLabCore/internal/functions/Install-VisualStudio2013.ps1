function Install-VisualStudio2013
{
    [cmdletBinding()]
    param (
        [int]$InstallationTimeout = (Get-LabConfigurationItem -Name Timeout_VisualStudio2013Installation)
    )

    Write-LogFunctionEntry

    $roleName = [AutomatedLab.Roles]::VisualStudio2013

    if (-not (Get-LabVM))
    {
        Write-ScreenInfo -Message 'No machine definitions imported, so there is nothing to do. Please use Import-Lab first' -Type Warning
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM -Role $roleName | Where-Object HostType -eq 'HyperV'

    if (-not $machines)
    {
        return
    }

    $isoImage = $Script:data.Sources.ISOs | Where-Object Name -eq $roleName
    if (-not $isoImage)
    {
        Write-LogFunctionExitWithError -Message "There is no ISO image available to install the role '$roleName'. Please add the required ISO to the lab and name it '$roleName'"
        return
    }

    Write-ScreenInfo -Message 'Waiting for machines to startup' -NoNewline
    Start-LabVM -RoleName $roleName -Wait -ProgressIndicator 15

    $jobs = @()

    Mount-LabIsoImage -ComputerName $machines -IsoPath $isoImage.Path -SupressOutput

    foreach ($machine in $machines)
    {
        $parameters = @{ }
        $parameters.Add('ComputerName', $machine.Name)
        $parameters.Add('ActivityName', 'InstallationVisualStudio2013')
        $parameters.Add('Verbose', $VerbosePreference)
        $parameters.Add('Scriptblock', {
                Write-Verbose 'Installing Visual Studio 2013'

                Push-Location
                Set-Location -Path (Get-WmiObject -Class Win32_CDRomDrive).Drive
                $exe = Get-ChildItem -Filter *.exe
                if ($exe.Count -gt 1)
                {
                    Write-Error 'More than one executable found, cannot proceed. Make sure you have defined the correct ISO image'
                    return
                }
                Write-Verbose "Calling '$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log'"
                Invoke-Expression -Command "$($exe.FullName) /quiet /norestart /noweb /Log c:\VsInstall.log"
                Pop-Location

                Write-Verbose 'Waiting 120 seconds'
                Start-Sleep -Seconds 120

                $installationStart = Get-Date
                $installationTimeoutInMinutes = 120
                $installationFinished = $false

                Write-Verbose "Looping until '*Exit code: 0x<digits>, restarting: No' is detected in the VsInstall.log..."
                while (-not $installationFinished)
                {
                    if ((Get-Content -Path C:\VsInstall.log | Select-Object -Last 1) -match '(?<Text1>Exit code: 0x)(?<ReturnCode>\w*)(?<Text2>, restarting: No$)')
                    {
                        $installationFinished = $true
                        Write-Verbose 'Visual Studio installation finished'
                    }
                    else
                    {
                        Write-Verbose 'Waiting for the Visual Studio installation...'
                    }

                    if ($installationStart.AddMinutes($installationTimeoutInMinutes) -lt (Get-Date))
                    {
                        Write-Error "The installation of Visual Studio did not finish within the timeout of $installationTimeoutInMinutes minutes"
                        break
                    }

                    Start-Sleep -Seconds 5
                }
                $matches.ReturnCode
                Write-Verbose '...Installation seems to be done'
            }
        )

        $jobs += Invoke-LabCommand @parameters -AsJob -PassThru -NoDisplay
    }

    Write-ScreenInfo -Message 'Waiting for Visual Studio 2013 to complete installation' -NoNewline

    Wait-LWLabJob -Job $jobs -ProgressIndicator 60 -Timeout $InstallationTimeout -NoDisplay

    foreach ($job in $jobs)
    {
        $result = Receive-Job -Job $job
        if ($result -ne 0)
        {
            $ipAddress = (Get-Job -Id $job.id).Location
            $machineName = (Get-LabVM | Where-Object {$_.IpV4Address -eq $ipAddress}).Name
            Write-ScreenInfo -Type Warning "Installation generated error or warning for machine '$machineName'. Return code is: $result"
        }
    }

    Dismount-LabIsoImage -ComputerName $machines -SupressOutput

    Write-LogFunctionExit
}
