function Dismount-LWIsoImage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseCompatibleCmdlets", "", Justification="Not relevant on Linux")]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$ComputerName
    )

    $machines = Get-LabVM -ComputerName $ComputerName

    foreach ($machine in $machines)
    {
        $vm = Get-LWHypervVM -Name $machine.ResourceName -ErrorAction SilentlyContinue
        if ($machine.OperatingSystem.Version -ge [System.Version]'6.2')
        {
            Write-PSFMessage -Message "Removing DVD drive for machine '$machine'"
            $vm | Get-VMDvdDrive | Remove-VMDvdDrive
        }
        else
        {
            Write-PSFMessage -Message "Setting DVD drive for machine '$machine' to null"
            $vm | Get-VMDvdDrive | Set-VMDvdDrive -Path $null
        }
    }
}
