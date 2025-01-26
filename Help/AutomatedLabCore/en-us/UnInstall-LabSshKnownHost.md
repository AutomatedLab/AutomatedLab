---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/UnInstall-LabSshKnownHost
schema: 2.0.0
---

# UnInstall-LabSshKnownHost

## SYNOPSIS
Remove lab VMs from SSH known hosts file

## SYNTAX

```
UnInstall-LabSshKnownHost [-ComputerName <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Remove lab VMs from SSH known hosts file

## EXAMPLES

### Example 1
```
PS C:\> UnInstall-LabSshKnownHost
```

Remove lab VMs from SSH known hosts file

## PARAMETERS

### -ComputerName
The machine or machines to scan keys for. Remove-LabVm does this
automatically, while Remove-Lab removes all lab machines from known hosts.

```yaml
Type: String[]
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

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
