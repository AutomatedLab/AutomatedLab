---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Connect-LabVM

## SYNOPSIS
Connect to a lab VM

## SYNTAX

```
Connect-LabVM [-ComputerName] <String[]> [-UseLocalCredential] [<CommonParameters>]
```

## DESCRIPTION
Gets the connection information for Azure and HyperV VMs and uses the information to open a Remote Desktop Session to those machines

## EXAMPLES

### Example 1


```powershell
Connect-LabVM -ComputerName DC1,DC2 -Credential (Get-Credential)
```

Connects the machines DC1 and DC2 via Remote Desktop and the credentials specified in Get-Credential

## PARAMETERS

### -ComputerName
The computer names to connect to

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

### -UseLocalCredential
Switch parameter to indicate if a local user credential of the machine should be used

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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
