---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Enable-LabCertificateAutoenrollment
schema: 2.0.0
---

# Enable-LabCertificateAutoenrollment

## SYNOPSIS
Enable certificate auto-enrollment

## SYNTAX

```
Enable-LabCertificateAutoenrollment [-Computer] [-User] [-CodeSigning] [[-CodeSigningTemplateName] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Enables the auto-enrollment for machines, including code-signing certificates

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabCertificateAutoEnrollent -Computer -User
```

Configure auto-enrollment for user and machine certificates

## PARAMETERS

### -CodeSigning
Indicates that code-signing certificates should be auto-enrolled

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

### -CodeSigningTemplateName
The code signing template to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Computer
Indicates that machine certificates should be auto-enrolled

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

### -User
Indicates that user certificates should be auto-enrolled

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

