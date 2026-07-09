function Get-LWProxmoxVMSysprepState {
    <#
    .SYNOPSIS
        Gets the sysprep state of Proxmox virtual machines.

    .DESCRIPTION
        This function retrieves the Windows sysprep state from the registry of one or more Proxmox virtual machines.
        It queries the ImageState value from HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State to determine
        the current sysprep status of each machine.

    .PARAMETER ComputerName
        The name(s) of the computer(s) to query for sysprep state. This parameter accepts an array of strings
        representing the computer names of Proxmox virtual machines.

    .EXAMPLE
        Get-LWProxmoxVMSysprepState -ComputerName 'Server01'

        Gets the sysprep state for a single virtual machine named Server01.

    .EXAMPLE
        Get-LWProxmoxVMSysprepState -ComputerName 'Server01', 'Server02', 'Server03'

        Gets the sysprep state for multiple virtual machines.
    #>
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    $results = Invoke-LabCommand -ActivityName 'Get Sysprep State' -ComputerName $ComputerName -NoDisplay -ScriptBlock {
        Get-ItemPropertyValue -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State -Name ImageState
    } -PassThru -UseLocalCredential

    foreach ($result in $results) {
        $vm = Get-LabVM | Where-Object { $_.IpAddress.IpAddress.AddressAsString -eq $result.PSComputerName }
        [pscustomobject]@{
            ComputerName = $vm.ResourceName
            SysprepState = $result
        }
    }
}
