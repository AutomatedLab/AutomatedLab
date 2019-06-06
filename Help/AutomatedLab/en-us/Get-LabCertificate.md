---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version:
schema: 2.0.0
---

# Get-LabCertificate

## SYNOPSIS
{{ Fill in the Synopsis }}

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
{{ Fill in the Description }}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -All
{{ Fill All Description }}

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

### -ComputerName
{{ Fill ComputerName Description }}

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

### -FindType
{{ Fill FindType Description }}

```yaml
Type: X509FindType
Parameter Sets: FindCer, FindPfx
Aliases:
Accepted values: FindByThumbprint, FindBySubjectName, FindBySubjectDistinguishedName, FindByIssuerName, FindByIssuerDistinguishedName, FindBySerialNumber, FindByTimeValid, FindByTimeNotYetValid, FindByTimeExpired, FindByTemplateName, FindByApplicationPolicy, FindByCertificatePolicy, FindByExtension, FindByKeyUsage, FindBySubjectKeyIdentifier

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeServices
{{ Fill IncludeServices Description }}

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

### -Location
{{ Fill Location Description }}

```yaml
Type: CertStoreLocation
Parameter Sets: (All)
Aliases:
Accepted values: CERT_SYSTEM_STORE_CURRENT_USER, CERT_SYSTEM_STORE_LOCAL_MACHINE, CERT_SYSTEM_STORE_SERVICES, CERT_SYSTEM_STORE_USERS

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
{{ Fill Password Description }}

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

### -SearchString
{{ Fill SearchString Description }}

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

### -ServiceName
{{ Fill ServiceName Description }}

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

### -Store
{{ Fill Store Description }}

```yaml
Type: StoreName
Parameter Sets: (All)
Aliases:
Accepted values: AddressBook, AuthRoot, CertificateAuthority, Disallowed, My, Root, TrustedPeople, TrustedPublisher

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
