---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/New-LabCATemplate
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
PS C:\> New-LabCATemplate  -TemplateName CustomWebServer -DisplayName 'Contoso Web' -SourceTemplateName WebServer -ValidityPeriod '90.00:00:00'
```

Create a new template CustomWebServer with a validity period of 90 days from the template WebServer on the Lab CA

## PARAMETERS

### -ApplicationPolicy
The names of the application policies

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:
Accepted values: EFS_RECOVERY, Auto Update CA Revocation, No OCSP Failover to CRL, OEM_WHQL_CRYPTO, Windows TCB Component, DNS Server Trust, Windows Third Party Application Component, ANY_APPLICATION_POLICY, KP_LIFETIME_SIGNING, Disallowed List, DS_EMAIL_REPLICATION, LICENSE_SERVER, KP_KEY_RECOVERY, Windows Kits Component, AUTO_ENROLL_CTL_USAGE, PKIX_KP_TIMESTAMP_SIGNING, Windows Update, Document Encryption, KP_CTL_USAGE_SIGNING, IPSEC_KP_IKE_INTERMEDIATE, PKIX_KP_IPSEC_TUNNEL, Code Signing, KP_KEY_RECOVERY_AGENT, KP_QUALIFIED_SUBORDINATION, Early Launch Antimalware Driver, Remote Desktop, WHQL_CRYPTO, EMBEDDED_NT_CRYPTO, System Health Authentication, DRM, PKIX_KP_EMAIL_PROTECTION, KP_TIME_STAMP_SIGNING, Protected Process Light Verification, Endorsement Key Certificate, KP_IPSEC_USER, PKIX_KP_IPSEC_END_SYSTEM, LICENSES, Protected Process Verification, IdMsKpScLogon, HAL Extension, KP_OCSP_SIGNING, Server Authentication, Auto Update End Revocation, KP_EFS, KP_DOCUMENT_SIGNING, Windows Store, Kernel Mode Code Signing, ENROLLMENT_AGENT, ROOT_LIST_SIGNER, Windows RT Verification, NT5_CRYPTO, Revoked List Signer, Microsoft Publisher, Platform Certificate, Windows Software Extension Verification, KP_CA_EXCHANGE, PKIX_KP_IPSEC_USER, Dynamic Code Generator, Client Authentication, DRM_INDIVIDUALIZATION

Required: False
Position: 3
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

### -EnrollmentFlags
The enrollment flags for the template

```yaml
Type: EnrollmentFlags
Parameter Sets: (All)
Aliases:
Accepted values: None, IncludeSymmetricAlgorithms, CAManagerApproval, KraPublish, DsPublish, AutoenrollmentCheckDsCert, Autoenrollment, ReenrollExistingCert, RequireUserInteraction, RemoveInvalidFromStore, AllowEnrollOnBehalfOf, IncludeOcspRevNoCheck, ReuseKeyTokenFull, BasicConstraintsInEndEntityCerts, IgnoreEnrollOnReenrollment, IssuancePoliciesFromRequest

Required: False
Position: 4
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
Accepted values: NO_KEY_USAGE, ENCIPHER_ONLY_KEY_USAGE, CRL_SIGN, KEY_CERT_SIGN, KEY_AGREEMENT, DATA_ENCIPHERMENT, KEY_ENCIPHERMENT, NON_REPUDIATION, DIGITAL_SIGNATURE, DECIPHER_ONLY_KEY_USAGE

Required: False
Position: 6
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
Accepted values: None, RequireKeyArchival, AllowKeyExport, RequireStrongProtection, RequireAlternateSignatureAlgorithm, ReuseKeysRenewal, UseLegacyProvider, TrustOnUse, ValidateCert, ValidateKey, Preferred, Required, WithoutPolicy, xxx

Required: False
Position: 5
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

