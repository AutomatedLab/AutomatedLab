function Get-LWHypervVMStatus
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    Write-LogFunctionEntry

    $result = @{ }
    $vms = Get-LWHypervVM -Name $ComputerName -ErrorAction SilentlyContinue
    $vmTable = @{ }
    Get-LabVm -IncludeLinux | Where-Object FriendlyName -in $ComputerName | ForEach-Object {$vmTable[$_.FriendlyName] = $_.Name}

    foreach ($vm in $vms)
    {
        $vmName = if ($vmTable[$vm.Name]) {$vmTable[$vm.Name]} else {$vm.Name}
        if ($vm.State -eq 'Running')
        {
            $result.Add($vmName, 'Started')
        }
        elseif ($vm.State -eq 'Off')
        {
            $result.Add($vmName, 'Stopped')
        }
        else
        {
            $result.Add($vmName, 'Unknown')
        }
    }

    $result

    Write-LogFunctionExit
}
