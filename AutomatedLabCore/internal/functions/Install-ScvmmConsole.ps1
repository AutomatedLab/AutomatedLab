function Install-ScvmmConsole
{
    [CmdletBinding()]
    param
    (
        [AutomatedLab.Machine[]]
        $Computer
    )

    foreach ($vm in $Computer)
    {
        $iniConsole = $iniContentConsoleScvmm.Clone()
        $role = $vm.Roles | Where-Object Name -in Scvmm2016, Scvmm2019, Scvmm2022
        if ($role.Properties -and [Convert]::ToBoolean($role.Properties['SkipServer']))
        {
            foreach ($property in $role.Properties.GetEnumerator())
            {
                if (-not $iniConsole.ContainsKey($property.Key)) { continue }
                $iniConsole[$property.Key] = $property.Value
            }
            $iniConsole.ProgramFiles = $iniConsole.ProgramFiles -f $role.Name.ToString().Substring(5)

            $scvmmIso = Mount-LabIsoImage -ComputerName $vm -IsoPath ($lab.Sources.ISOs | Where-Object { $_.Name -eq $role.Name }).Path -SupressOutput -PassThru

            Invoke-LabCommand -ComputerName $vm -Variable (Get-Variable iniConsole, scvmmIso) -ActivityName 'Extracting SCVMM Console' -ScriptBlock {
                $setup = Get-ChildItem -Path $scvmmIso.DriveLetter -Filter *.exe | Select-Object -First 1
                Start-Process -FilePath $setup.FullName -ArgumentList '/VERYSILENT', '/DIR=C:\SCVMM' -Wait
                '[OPTIONS]' | Set-Content C:\Console.ini
                $iniConsole.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" | Add-Content C:\Console.ini }
                "cd C:\SCVMM; C:\SCVMM\setup.exe /client /i /f C:\Console.ini /IACCEPTSCEULA" | Set-Content C:\DeployDebug\VmmSetup.cmd
                Set-Location -Path C:\SCVMM
            }

            Install-LabSoftwarePackage -ComputerName $vm -WorkingDirectory C:\SCVMM -LocalPath C:\SCVMM\setup.exe -CommandLine '/client /i /f C:\Console.ini /IACCEPTSCEULA' -AsJob -PassThru -UseShellExecute -Timeout 20
            Dismount-LabIsoImage -ComputerName $vm -SupressOutput
        }
    }
}
