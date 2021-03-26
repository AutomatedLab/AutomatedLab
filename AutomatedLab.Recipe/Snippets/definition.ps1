$snippet = {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [string]
        $VmPath,

        [int]
        $ReferenceDiskSizeInGB,

        [long]
        $MaxMemory,

        [string]
        $Notes,

        [switch]
        $UseAllMemory,

        [switch]
        $UseStaticMemory,

        [Parameter(Mandatory)]
        [string]
        $DefaultVirtualizationEngine,

        [string]
        $SubscriptionName,

        [string]
        $DefaultLocationName,

        [string]
        $DefaultStorageAccountName,

        [string]
        $DefaultResourceGroupName,

        [timespan]
        $AutoShutdownTime,

        [timezoneinfo]
        $AutoShutdownTimeZone,

        [switch]
        $AllowBastionHost,

        [pscredential]
        $AdminCredential,

        [Parameter(Mandatory)]
        [AutomatedLab.IpNetwork]
        $MachineNetwork,

        [ValidateLength(1,10)]
        [string]
        $VmNamePrefix
    )

    $defParam = Sync-Parameter -Command (Get-Command New-LabDefinition) -Parameters $PSBoundParameters
    New-LabDefinition @defParam

    $PSDefaultParameterValues['Add-LabMachineDefinition:Network'] = $Name

    if (-not $VmNamePrefix)
    {
        $VmNamePrefix = $Name.ToUpper()
    }
    
    $AutomatedLabVmNamePrefix = $VmNamePrefix
    

    if ($SubscriptionName)
    {
        $azParam = Sync-Parameter -Command (Get-Command Add-LabAzureSubscription) -Parameters $PSBoundParameters
        Add-LabAzureSubscription @azParam
    }

    if ($MachineNetwork)
    {
        Add-LabVirtualNetworkDefinition -Name $Name -AddressSpace $MachineNetwork
    }

    if ($AdminCredential)
    {
        Set-LabInstallationCredential -Username $AdminCredential.UserName -Password $AdminCredential.GetNetworkCredential().Password
    }
}

New-LabSnippet -Name LabDefinition -Description 'Basic snippet to create a new labdefinition' -Tag Definition -Type Snippet -ScriptBlock $snippet -NoExport -Force
