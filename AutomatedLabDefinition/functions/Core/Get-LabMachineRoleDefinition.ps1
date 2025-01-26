function Get-LabMachineRoleDefinition {
    [CmdletBinding(DefaultParameterSetName = 'Role')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Role')]
        [AutomatedLab.Roles]
        $Role,

        [Parameter(ParameterSetName = 'Role')]
        [hashtable]
        $Properties,

        [Parameter(ParameterSetName = 'Role')]
        [switch]
        $Syntax,

        [Parameter(ParameterSetName = 'List')]
        [switch]
        $List
    )

    $roleObjects = @()
    $availableRoles = [Enum]::GetNames([AutomatedLab.Roles])
    $config = Get-LabConfigurationItem -Name ValidationSettings

    if ($List.IsPresent) {
        $availableRoles | Where-Object { $_.ToString() -notin 'ADDS', 'SQLServer', 'SharePoint', 'SCVMM', 'SCOM', 'Dynamics', 'RDS' } | ForEach-Object {
            [PSCustomObject]@{
                Role                = $_.ToString()
                MandatoryProperties = $config.MandatoryRoleProperties[$_.ToString()]
                ValidProperties     = $config.ValidRoleProperties[$_.ToString()].Keys
            }
        }
        return
    }

    foreach ($availableRole in $availableRoles) {
        if ($Role.HasFlag([AutomatedLab.Roles]$availableRole)) {            
            if ($Syntax.IsPresent -and $config.ValidRoleProperties.Contains($availableRole.ToString())) {
                $roleParams = foreach ($parameter in ($config.ValidRoleProperties[$availableRole.ToString()].GetEnumerator() | Sort-Object Key)) {
                    $paramType = if ($config.MandatoryRoleProperties[$availableRole.ToString()]) { '(Required)' } else { '(Optional)' }
                    "    $($parameter.Key) = '$paramType $($parameter.Value)'`r`n"
                }
                $roleObjects += "Get-LabMachineRoleDefinition -Role $availableRole -Properties @{`r`n$roleParams}`r`n"
            }
            elseif ($Syntax.IsPresent -and -not $config.ValidRoleProperties.Contains($availableRole.ToString())) {
                $roleObjects += "Get-LabMachineRoleDefinition -Role $availableRole`r`n"
            }
            else {
                $roleObject = New-Object -TypeName AutomatedLab.Role
                $roleObject.Name = $availableRole
                $roleObject.Properties = $Properties

                $roleObjects += $roleObject
            }
        }
    }

    return $roleObjects
}
