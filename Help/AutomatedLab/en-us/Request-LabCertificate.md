---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Request-LabCertificate
schema: 2.0.0
---

# Request-LabCertificate

## SYNOPSIS
Request a certificate

## SYNTAX

```
Request-LabCertificate [-Subject] <String> [[-SAN] <String[]>] [[-OnlineCA] <String>] [-TemplateName] <String>
 [-ComputerName] <String[]> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Requests a certificate from the lab CA

## EXAMPLES

### Example 1
```powershell
PS C:\> Request-LabCertificate -Subject 'CN=ClusterName' -SAN 'ClusterName.contoso.com' -TemplateName WebServer -ComputerName POSHWEB1
```

Request a new SSL certificate for POSHWEB1 from the Lab CA

## PARAMETERS

### -ComputerName
The machine for which a certificate is to be requested

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OnlineCA
The CA to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the certificate should be passed back to the caller

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

### -SAN
The subject alternative names

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subject
The certificate's subject

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TemplateName
The template to use

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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

