---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Disconnect-Lab

## SYNOPSIS
Disconnects two labs

## SYNTAX

```
Disconnect-Lab [-SourceLab] <Object> [-DestinationLab] <Object> [<CommonParameters>]
```

## DESCRIPTION
Takes the necessary steps to disconnect two previously connected labs.
On Azure, it will remove all created ressources (s2sip, s2sgw, onpremgw and s2sconnection).
On the on-premises router it will Uninstall-RemoteAccess -VpnType S2SVPN

## EXAMPLES

### Example 1
```powershell
PS C:\> Disconnect-Lab -SourceLab OnPrem -DestinationLab AzLab
```

Removes the VPN connection between OnPrem and AzLab

## PARAMETERS

### -SourceLab
The source lab name

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DestinationLab
The destination lab name

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
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
