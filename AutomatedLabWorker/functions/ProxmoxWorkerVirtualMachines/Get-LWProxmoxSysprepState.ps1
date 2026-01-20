function Get-LWProxmoxSysprepState {
    param (
        [Parameter(Mandatory)]
        [string[]]$ComputerName
    )

    $results = Invoke-LabCommand -ActivityName 'Get Sysprep State' -ComputerName $ComputerName -ScriptBlock {
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
