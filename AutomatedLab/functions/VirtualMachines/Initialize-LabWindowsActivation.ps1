function Initialize-LabWindowsActivation
{
    [CmdletBinding()]
    param ()

    Write-LogFunctionEntry

    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab)
    {
        Write-ScreenInfo -Type Warning -Message 'No lab imported, skipping activation'
        Write-LogFunctionExit
        return
    }

    $machines = Get-LabVM | Where-Object {$_.SkipDeployment -eq $false -and $_.OperatingSystemType -eq 'Windows' -and (($_.Notes.ContainsKey('ActivateWindows') -and $_.Notes['ActivateWindows']) -or $_.Notes.ContainsKey('KmsLookupDomain') -or $_.Notes.ContainsKey('KmsServerName'))}

    if (-not $machines) { Write-LogFunctionExit; return }

    Invoke-LabCommand -ActivityName 'Activating Windows' -ComputerName $machines -Variable (Get-Variable machines) -ScriptBlock {
        $machine = $machines | Where-Object Name -eq $env:COMPUTERNAME

        if (-not $machine) { return }

        $licensing = Get-CimInstance -ClassName SoftwareLicensingService

        if ($machine.Notes.ContainsKey('KmsLookupDomain'))
        {
            $null = $licensing | Invoke-CimMethod -MethodName SetKeyManagementServiceLookupDomain -Arguments @{LookupDomain = $machines.Notes['KmsLookupDomain']}
        }
        elseif ($machines.Notes.ContainsKey('KmsServerName') -and $machines.Notes.ContainsKey('KmsPort'))
        {
            $null = $licensing | Invoke-CimMethod -MethodName SetKeyManagementServiceMachine -Arguments @{MachineName = $machines.Notes['KmsServerName']}
            $null = $licensing | Invoke-CimMethod -MethodName SetKeyManagementServicePort -Arguments @{PortNumber = $machines.Notes['KmsPort']}
        }
        elseif ($machines.Notes.ContainsKey('KmsServerName'))
        {
            $null = $licensing | Invoke-CimMethod -MethodName SetKeyManagementServiceMachine -Arguments @{MachineName = $machines.Notes['KmsServerName']}
        }
        elseif ($machine.ProductKey)
        {
            $null = $licensing | Invoke-CimMethod -MethodName InstallProductKey -Arguments @{ProductKey = $machine.ProductKey}
        }

        $null = $licensing | Invoke-CimMethod -MethodName RefreshLicenseStatus
    }

    Write-LogFunctionExit
}
