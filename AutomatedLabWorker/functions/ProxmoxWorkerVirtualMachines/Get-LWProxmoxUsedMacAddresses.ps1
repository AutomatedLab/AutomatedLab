function Get-LWProxmoxUsedMacAddresses {
    param (
        [Parameter()]
        [switch]$NoSeparator
    )

    $vmConfigs = Get-LWProxmoxVMConfig -IncludeTemplates

    $macAddresses = foreach ($vmConfig in $vmConfigs) {
        $netProperties = $vmConfig | Get-Member -Name 'net*' -MemberType NoteProperty
        foreach ($netProperty in $netProperties) {
            $net = $vmConfig.$($netProperty.Name)
            # Example net property: net0: virtio=BC:24:11:B9:43:18,bridge=RDS,firewall=1
            # We need to extract the MAC address value after the adapter type (virtio, vmxnet3, e1000, e1000e, or rtl8139)
            $macMatch = $net -match '(?:virtio|vmxnet3|e1000e?|rtl8139)=([0-9A-Fa-f:]{17})'
            if ($macMatch) {
                if ($NoSeparator) {
                    $matches[1] -replace ':', ''
                }
                else {
                    $matches[1]
                }
            }
        }
    }

    return $macAddresses | Sort-Object -Unique
}
