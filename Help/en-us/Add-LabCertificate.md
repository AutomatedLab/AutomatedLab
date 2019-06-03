---
external help file: AutomatedLab.Help.xml
Module Name: automatedlab
online version:
schema: 2.0.0
---

# Add-LabCertificate

## SYNOPSIS

Import a certificate to a certificate store on one or more lab VMs

## SYNTAX

### ByteArray (Default)
```
Add-LabCertificate -RawContentBytes <Byte[]> -Store <StoreName> -Location <CertStoreLocation>
 [-ServiceName <String>] [-CertificateType <String>] [-Password <String>] -ComputerName <String[]>
 [<CommonParameters>]
```

### File
```
Add-LabCertificate -Path <String> -Store <StoreName> -Location <CertStoreLocation> [-ServiceName <String>]
 [-CertificateType <String>] [-Password <String>] -ComputerName <String[]> [<CommonParameters>]
```

## DESCRIPTION

Import a certificate to a certificate store on one or more lab VMs. Supports both the raw byte content as
well as the CER/PFX path of an existing certificate.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-LabCertificate -Path .\CodeSigning.pfx -Store My -Location CERT_SYSTEM_STORE_LOCAL_MACHINE -CertificateType Pfx -Password 555Nase -ComputerName (Get-LabVM)
```

Install a PFX certificate on all lab machines

## PARAMETERS

### -Store
Certificate store, e.g. My

```yaml
Type: StoreName
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Location
The cert store location

```yaml
Type: CertStoreLocation
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ServiceName
Name of the service, if any

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CertificateType
The cert type, PFX or CER

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Password
The password to decrypt the PFX private key

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ComputerName
The remote hosts

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Path
The path to the cer/pfx file

```yaml
Type: String
Parameter Sets: File
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -RawContentBytes
The byte content of the certificate, i.e. from Get-LabCertificate

```yaml
Type: Byte[]
Parameter Sets: ByteArray
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
