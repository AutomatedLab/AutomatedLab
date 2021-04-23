$snippet = {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $DomainName,

        [Parameter(Mandatory)]
        [pscredential]
        $AdminCredential,

        [uint16]
        $DomainControllerCount,

        [uint16]
        $RodcCount,

        [switch]
        $IsSubDomain
    )

    if (-not $AutomatedLabFirstRoot)
    {
        $AutomatedLabFirstRoot = $DomainName
    }

    if (-not $globalDcCount)
    {
        $globalDcCount = 1
    }

    Add-LabDomainDefinition -Name $DomainName -AdminUser $AdminCredential.UserName -AdminPassword $AdminCredential.GetNetworkCredential().Password

    $role = if ($IsSubDomain) { Get-LabMachineRoleDefinition -Role 'FirstChildDc' } else { Get-LabMachineRoleDefinition -Role 'RootDc' }
    Add-LabMachineDefinition -Name ('{0}DC{1:d2}' -f $AutomatedLabVmNamePrefix, $globalDcCount) -Roles $role -DomainName $DomainName
    $globalDcCount++

    if ($DomainControllerCount -gt 0)
    {
        foreach ($count in 1..$DomainControllerCount)
        {
            Add-LabMachineDefinition -Name ('{0}DC{1:d2}' -f $AutomatedLabVmNamePrefix, $globalDcCount) -Roles DC -DomainName $DomainName
            $globalDcCount++
        }
    }

    if ($RodcCount -gt 0)
    {
        foreach ($count in 1..$RodcCount)
        {
            $role = Get-LabMachineRoleDefinition -Role DC -Properties @{ IsReadOnly = '1' }
            Add-LabMachineDefinition -Name ('{0}DC{1:d2}' -f $AutomatedLabVmNamePrefix, $globalDcCount) -Roles $role -DomainName $DomainName
            $globalDcCount++
        }
    }
}

New-LabSnippet -Name Domain -Description 'Basic snippet to add one or more domains' -Tag Domain -Type Snippet -ScriptBlock $snippet -DependsOn LabDefinition -Force -NoExport
