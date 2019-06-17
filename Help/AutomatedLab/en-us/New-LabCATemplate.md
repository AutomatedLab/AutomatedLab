---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# New-LabCATemplate

## SYNOPSIS
Create CA template

## SYNTAX

```
New-LabCATemplate [-TemplateName] <String> [[-DisplayName] <String>] [-SourceTemplateName] <String>
 [[-ApplicationPolicy] <String[]>] [[-EnrollmentFlags] <EnrollmentFlags>]
 [[-PrivateKeyFlags] <PrivateKeyFlags>] [[-KeyUsage] <KeyUsage>] [[-Version] <Int32>]
 [[-ValidityPeriod] <TimeSpan>] [[-RenewalPeriod] <TimeSpan>] [-SamAccountName] <String[]>
 [-ComputerName] <String> [<CommonParameters>]
```

## DESCRIPTION
Creates a new certificate template in the lab certificate authority

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -TemplateName
The name of the new CA template

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

### -DisplayName
The display name of the template

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceTemplateName
The name of the source template

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicationPolicy
The names of the application policies

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnrollmentFlags
The enrollment flags for the template

```yaml
Type: EnrollmentFlags
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrivateKeyFlags
The private key usage flags

```yaml
Type: PrivateKeyFlags
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The template version

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValidityPeriod
The timespan certificates created from this template are valid for

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RenewalPeriod
The timespan after which certificates created by this template have to be renewed

```yaml
Type: TimeSpan
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SamAccountName
The SamAccountNames of users permitted to use the template

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The lab machine with the CA role

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyUsage
The keu usage type

```yaml
Type: KeyUsage
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
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
