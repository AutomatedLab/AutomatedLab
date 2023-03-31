function Get-LabMachineRoleDefinition
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AutomatedLab.Roles]
        $Role,

        [hashtable]
        $Properties,

        [switch]
        $Syntax
    )

    $roleObjects = @()
    $availableRoles = [Enum]::GetNames([AutomatedLab.Roles])
    $config = Get-LabConfigurationItem -Name ValidationSettings

    foreach ($availableRole in $availableRoles)
    {
        if ($Role.HasFlag([AutomatedLab.Roles]$availableRole))
        {            
            if ($Syntax.IsPresent -and $config.ValidRoleProperties.Contains($availableRole.ToString()))
            {
                $roleObjects += "Get-LabMachineRoleDefinition -Role $availableRole -Properties @{`r`n$($config.ValidRoleProperties[$availableRole.ToString()] -join `"='value'`r`n`")='value'`r`n}`r`n"
            }
            elseif ($Syntax.IsPresent -and -not $config.ValidRoleProperties.Contains($availableRole.ToString()))
            {
                $roleObjects += "Get-LabMachineRoleDefinition -Role $availableRole`r`n"
            }
            else
            {
                $roleObject = New-Object -TypeName AutomatedLab.Role
                $roleObject.Name = $availableRole
                $roleObject.Properties = $Properties

                $roleObjects += $roleObject
            }
        }
    }

    return $roleObjects
}
