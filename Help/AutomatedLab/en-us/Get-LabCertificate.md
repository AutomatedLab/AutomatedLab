---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabCertificate

## SYNOPSIS

## SYNTAX

### FindCer (Default)
```
Get-LabCertificate -SearchString <String> -FindType <X509FindType> [-Location <CertStoreLocation>]
 [-Store <StoreName>] [-ServiceName <String>] -ComputerName <String[]> [<CommonParameters>]
```

### FindPfx
```
Get-LabCertificate -SearchString <String> -FindType <X509FindType> [-Location <CertStoreLocation>]
 [-Store <StoreName>] [-ServiceName <String>] -Password <SecureString> [-ExportPrivateKey]
 -ComputerName <String[]> [<CommonParameters>]
```

### AllPfx
```
Get-LabCertificate [-Location <CertStoreLocation>] [-Store <StoreName>] [-ServiceName <String>] [-All]
 [-IncludeServices] -Password <SecureString> [-ExportPrivateKey] -ComputerName <String[]> [<CommonParameters>]
```

### AllCer
```
Get-LabCertificate [-Location <CertStoreLocation>] [-Store <StoreName>] [-ServiceName <String>] [-All]
 [-IncludeServices] -ComputerName <String[]> [<CommonParameters>]
```

## DESCRIPTION

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -SearchString
@{Text=}

```yaml
Type: String
Parameter Sets: FindCer, FindPfx
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FindType
@{Text=}

```yaml
Type: X509FindType
Parameter Sets: FindCer, FindPfx
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
@{Text=}

```yaml
Type: CertStoreLocation
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Store
@{Text=}

```yaml
Type: StoreName
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceName
@{Text=}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
@{Text=}

```yaml
Type: SecureString
Parameter Sets: FindPfx, AllPfx
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
@{Text=}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
@{Text=}

```yaml
Type: SwitchParameter
Parameter Sets: AllPfx, AllCer
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeServices
@{Text=}

```yaml
Type: SwitchParameter
Parameter Sets: AllPfx, AllCer
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExportPrivateKey
{{ Fill ExportPrivateKey Description }}

```yaml
Type: SwitchParameter
Parameter Sets: FindPfx, AllPfx
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
