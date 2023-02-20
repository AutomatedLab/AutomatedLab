---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Get-LabCertificate
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
PS C:\> Get-LabCertificate -All -ComputerName Node1, Node2 -Location CERT_SYSTEM_STORE_LOCAL_MACHINE_ID
```

List all certificates on Node1 and Node2 in the local machine cert store.

### Example 2
```powershell
PS C:\> Get-LabCertificate -SearchString 'CN=Glorb' -FindType FindBySubjectName -ComputerName Node1, Node2
```

Find the certificate with the subject 'CN=Glorb' on Node1 and Node2

## PARAMETERS

### -All
Retrieve all certificates

```yaml
Type: SwitchParameter
Parameter Sets: AllPfx, AllCer
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
The hosts to get certificates from

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
Indicates that the private key should be exported

```yaml
Type: SwitchParameter
Parameter Sets: FindPfx, AllPfx
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FindType
Sets which attribute will be searched, e.g.
FindBySubjectName

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
Indicates that services will be included

```yaml
Type: SwitchParameter
Parameter Sets: AllPfx, AllCer
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Location
The location to search in.
Possible values CERT_SYSTEM_STORE_CURRENT_USER, CERT_SYSTEM_STORE_LOCAL_MACHINE, CERT_SYSTEM_STORE_SERVICES, CERT_SYSTEM_STORE_USERS

```yaml
Type: CertStoreLocation
Parameter Sets: (All)
Aliases:
Accepted values: CERT_SYSTEM_STORE_CURRENT_USER_ID, CERT_SYSTEM_STORE_LOCAL_MACHINE_ID, CERT_SYSTEM_STORE_CURRENT_SERVICE_ID, CERT_SYSTEM_STORE_SERVICES_ID, CERT_SYSTEM_STORE_USERS_ID, CERT_SYSTEM_STORE_CURRENT_USER_GROUP_POLICY_ID, CERT_SYSTEM_STORE_LOCAL_MACHINE_GROUP_POLICY_ID, CERT_SYSTEM_STORE_LOCAL_MACHINE_ENTERPRISE_ID, CERT_SYSTEM_STORE_LOCATION_SHIFT, CERT_SYSTEM_STORE_CURRENT_USER, CERT_SYSTEM_STORE_LOCAL_MACHINE, CERT_SYSTEM_STORE_CURRENT_SERVICE, CERT_SYSTEM_STORE_SERVICES, CERT_SYSTEM_STORE_USERS, CERT_SYSTEM_STORE_CURRENT_USER_GROUP_POLICY, CERT_SYSTEM_STORE_LOCAL_MACHINE_GROUP_POLICY, CERT_SYSTEM_STORE_LOCAL_MACHINE_ENTERPRISE, CERT_SYSTEM_STORE_LOCATION_MASK

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
The password used to decrypt the PFX private key

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
The search string to use.
For more information, see: https://docs.microsoft.com/en-us/dotnet/api/system.security.cryptography.x509certificates.x509certificate2collection.find

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
The name of the service

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
The store to look in, e.g.
My

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

## OUTPUTS

## NOTES

## RELATED LINKS

