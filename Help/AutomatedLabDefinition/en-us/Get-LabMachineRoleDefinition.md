---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Get-LabMachineRoleDefinition

## SYNOPSIS
Get a role definition

## SYNTAX

```
Get-LabMachineRoleDefinition [-Role] <Roles> [[-Properties] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Gets a role definition to be used with the parameter Roles for a new virtual machine definition

## EXAMPLES

### Example 1
```powershell
$role = Get-LabMachineRoleDefinition -Role FirstChildDC -Properties @{ ParentDomain = 'contoso.com'; NewDomain = 'child' }
Add-LabMachineDefinition -Name Host -Role $role
```

Gets a role definition for the first DC of a child domain with the additional properties ParentDomain = contoso.com and the child domain name NewDomain = child

## PARAMETERS

### -Role
The role names

```yaml
Type: Roles
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Properties
The properties for one role definition that can be set for the role, e.g.
$role = Get-LabMachineRoleDefinition -Role FirstChildDC -Properties @{ ParentDomain = 'contoso.com'; NewDomain = 'child' }

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
