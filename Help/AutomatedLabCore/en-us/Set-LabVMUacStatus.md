---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Set-LabVMUacStatus
schema: 2.0.0
---

# Set-LabVMUacStatus

## SYNOPSIS
Set the UAC

## SYNTAX

```
Set-LabVMUacStatus [-ComputerName] <String[]> [[-EnableLUA] <Boolean>] [[-ConsentPromptBehaviorAdmin] <Int32>]
 [[-ConsentPromptBehaviorUser] <Int32>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Sets the UAC for a lab machine

## EXAMPLES

### Example 1
```powershell
PS C:\> Set-LabVMUacStatus -ComputerName host1 -EnableLUA $true
```

Configure UAC on host1

## PARAMETERS

### -ComputerName
The computer names to set UAC on

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConsentPromptBehaviorAdmin
Sets the consent prompt behavior for administrative users

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConsentPromptBehaviorUser
Sets the consent prompt behavior for users

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableLUA
Indicates whether LUA should be enabled or not

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the results should be passed back to the caller

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

