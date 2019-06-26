---
external help file: PSLog-help.xml
Module Name: PSLog
online version:
schema: 2.0.0
---

# Get-CallerPreference

## SYNOPSIS
Fetches "Preference" variable values from the caller's scope.

## SYNTAX

### AllVariables (Default)
```
Get-CallerPreference -Cmdlet <Object> -SessionState <SessionState> [<CommonParameters>]
```

### Filtered
```
Get-CallerPreference -Cmdlet <Object> -SessionState <SessionState> [-Name <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Script module functions do not automatically inherit their caller's variables, but they can be
obtained through the $PSCmdlet variable in Advanced Functions. 
This function is a helper function
for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.

## EXAMPLES

### EXAMPLE 1
```powershell
Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
```

Imports the default PowerShell preference variables from the caller into the local scope.

### EXAMPLE 2
```powershell
Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'
```

Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.

### EXAMPLE 3
```powershell
'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
```

Same as Example 2, but sends variable names to the Name parameter via pipeline input.

## PARAMETERS

### -Cmdlet
The $PSCmdlet object from a script module Advanced Function.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SessionState
The $ExecutionContext.SessionState object from a script module Advanced Function. 
This is how the
Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
script module.

```yaml
Type: SessionState
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Optional array of parameter names to retrieve from the caller's scope. 
Default is to retrieve all
Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
This parameter may also specify names of variables that are not in the about_Preference_Variables
help file, and the function will retrieve and set those as well.

```yaml
Type: String[]
Parameter Sets: Filtered
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
## OUTPUTS

### None.  This function does not produce pipeline output.
## NOTES

## RELATED LINKS

[about_Preference_Variables]()

