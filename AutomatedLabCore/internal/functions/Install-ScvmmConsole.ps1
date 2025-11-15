function Install-ScvmmConsole
{
    [CmdletBinding()]
    param
    (
        [AutomatedLab.Machine[]]
        $Computer
    )
    $lab = Get-Lab
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

            Invoke-LabCommand -ComputerName $vm -Variable (Get-Variable iniConsole, scvmmIso, AL_DeployDebugFolder) -ActivityName 'Extracting SCVMM Console' -ScriptBlock {
                $deployDebug =  (Get-Item -Path $ExecutionContext.InvokeCommand.ExpandString($AL_DeployDebugFolder)).FullName
                $setup = Get-ChildItem -Path $scvmmIso.DriveLetter -Filter *.exe | Select-Object -First 1
                Start-Process -FilePath $setup.FullName -ArgumentList '/VERYSILENT', '/DIR=C:\SCVMM' -Wait
                '[OPTIONS]' | Set-Content C:\Console.ini
                $iniConsole.GetEnumerator() | ForEach-Object { "$($_.Key) = $($_.Value)" | Add-Content C:\Console.ini }
                "cd $deployDebug\SCVMM; $deployDebug\SCVMM\setup.exe /client /i /f $deployDebug\ScvmmConsole.ini /IACCEPTSCEULA" | Set-Content $deployDebug\VmmSetup.cmd
                Set-Location -Path $deployDebug\SCVMM
            }

            Install-LabSoftwarePackage -ComputerName $vm -WorkingDirectory C:\SCVMM -LocalPath C:\SCVMM\setup.exe -CommandLine "/client /i /f $deployDebug\ScvmmConsole.ini /IACCEPTSCEULA" -AsJob -PassThru -UseShellExecute -Timeout 20
            Dismount-LabIsoImage -ComputerName $vm -SupressOutput
        }
    }
}
