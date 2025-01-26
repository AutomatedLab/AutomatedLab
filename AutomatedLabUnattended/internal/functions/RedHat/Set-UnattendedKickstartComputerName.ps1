function Set-UnattendedKickstartComputerName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $existingLine = $script:un | Where-Object { $_ -match 'network' }
    if ($existingLine -like '*--hostname*') {
        $index = $script:un.IndexOf($existingLine)
        $script:un[$index] = $existingLine -replace '--hostname=\w+', "--hostname=$ComputerName"
        return
    }

    if ($existingLine) {
        $index = $script:un.IndexOf($existingLine)
        $script:un[$index] = '{0} {1}' -f $existingLine, "--hostname=$ComputerName"
        return
    }

    $script:un.Add("network --hostname=$ComputerName")
}
