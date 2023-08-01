---
external help file: AutomatedLabCore-help.xml
Module Name: AutomatedLabCore
online version: https://automatedlab.org/en/latest/AutomatedLabCore/en-us/Add-LabCertificate
schema: 2.0.0
---

# Add-LabCertificate

## SYNOPSIS

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

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-LabCertificate -Path C:\MyPublicKey.cer -Location CERT_SYSTEM_STORE_LOCAL_MACHINE_ID -ComputerName LabVM1
```

Add the certificate file MyPublicKey.cer to the local machine cert store on LabVM1

## PARAMETERS

### -CertificateType
The certificate type (cer, pfx)

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: CER, PFX

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ComputerName
The host to add the certificate to

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

### -Location
The location of the certificate store

```yaml
Type: CertStoreLocation
Parameter Sets: (All)
Aliases:
Accepted values: CERT_SYSTEM_STORE_CURRENT_USER_ID, CERT_SYSTEM_STORE_LOCAL_MACHINE_ID, CERT_SYSTEM_STORE_CURRENT_SERVICE_ID, CERT_SYSTEM_STORE_SERVICES_ID, CERT_SYSTEM_STORE_USERS_ID, CERT_SYSTEM_STORE_CURRENT_USER_GROUP_POLICY_ID, CERT_SYSTEM_STORE_LOCAL_MACHINE_GROUP_POLICY_ID, CERT_SYSTEM_STORE_LOCAL_MACHINE_ENTERPRISE_ID, CERT_SYSTEM_STORE_LOCATION_SHIFT, CERT_SYSTEM_STORE_CURRENT_USER, CERT_SYSTEM_STORE_LOCAL_MACHINE, CERT_SYSTEM_STORE_CURRENT_SERVICE, CERT_SYSTEM_STORE_SERVICES, CERT_SYSTEM_STORE_USERS, CERT_SYSTEM_STORE_CURRENT_USER_GROUP_POLICY, CERT_SYSTEM_STORE_LOCAL_MACHINE_GROUP_POLICY, CERT_SYSTEM_STORE_LOCAL_MACHINE_ENTERPRISE, CERT_SYSTEM_STORE_LOCATION_MASK

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Password
The password to decrypt the private key

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

### -Path
The path of the cer/pfx file

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
Certificate as Byte\[\]

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

### -ServiceName
The name of the service to add a certificate to

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

### -Store
The certificate store to add the cert to

```yaml
Type: StoreName
Parameter Sets: (All)
Aliases:
Accepted values: AddressBook, AuthRoot, CertificateAuthority, Disallowed, My, Root, TrustedPeople, TrustedPublisher

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

