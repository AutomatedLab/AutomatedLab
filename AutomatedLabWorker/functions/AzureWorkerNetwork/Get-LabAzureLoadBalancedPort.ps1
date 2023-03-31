function Get-LabAzureLoadBalancedPort
{
    param
    (
        [Parameter()]
        [uint16]
        $Port,

        [uint16]
        $DestinationPort,

        [Parameter(Mandatory)]
        [string]
        $ComputerName
    )

    $lab = Get-Lab -ErrorAction SilentlyContinue

    if (-not $lab)
    {
        Write-ScreenInfo -Type Warning -Message 'Lab data not available. Cannot list ports. Use Import-Lab to import an existing lab'
        return
    }

    $machine = Get-LabVm -ComputerName $ComputerName

    if (-not $machine)
    {
        Write-PSFMessage -Message "$ComputerName not found. Cannot list ports."
        return
    }

    $ports = if ($DestinationPort -and $Port)
    {
        $machine.InternalNotes.GetEnumerator() | Where-Object -Property Key -eq "AdditionalPort-$Port-$DestinationPort"
    }
    elseif ($DestinationPort)
    {
        $machine.InternalNotes.GetEnumerator() | Where-Object -Property Key -like "AdditionalPort-*-$DestinationPort"
    }
    elseif ($Port)
    {
        $machine.InternalNotes.GetEnumerator() | Where-Object -Property Key -like "AdditionalPort-$Port-*"
    }
    else
    {
        $machine.InternalNotes.GetEnumerator() | Where-Object -Property Key -like 'AdditionalPort*'
    }

    $ports | Foreach-Object {
        [pscustomobject]@{
            Port = ($_.Key -split '-')[1]
            DestinationPort = ($_.Key -split '-')[2]
            ComputerName = $machine.ResourceName
        }
    }
}
