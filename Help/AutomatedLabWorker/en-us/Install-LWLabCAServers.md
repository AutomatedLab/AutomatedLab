---
external help file: AutomatedLabWorker-help.xml
Module Name: AutomatedLabWorker
online version:
schema: 2.0.0
---

# Install-LWLabCAServers

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

```
Install-LWLabCAServers [-ComputerName] <String> [-DomainName] <String> [-UserName] <String>
 [-Password] <String> [[-ForestAdminUserName] <String>] [[-ForestAdminPassword] <String>]
 [[-ParentCA] <String>] [[-ParentCALogicalName] <String>] [-CACommonName] <String> [-CAType] <String>
 [-KeyLength] <String> [-CryptoProviderName] <String> [-HashAlgorithmName] <String>
 [-DatabaseDirectory] <String> [-LogDirectory] <String> [-CpsUrl] <String> [-CpsText] <String>
 [-UseLDAPAIA] <Boolean> [-UseHTTPAia] <Boolean> [-AIAHTTPURL01] <String> [-AiaHttpUrl02] <String>
 [-AIAHTTPURL01UploadLocation] <String> [-AiaHttpUrl02UploadLocation] <String> [-OCSPHttpUrl01] <String>
 [-OCSPHttpUrl02] <String> [-UseLDAPCRL] <Boolean> [-UseHTTPCRL] <Boolean> [-CDPHTTPURL01] <String>
 [-CDPHTTPURL02] <String> [-CDPHTTPURL01UploadLocation] <String> [-CDPHTTPURL02UploadLocation] <String>
 [-InstallOCSP] <Boolean> [[-ValidityPeriod] <String>] [[-ValidityPeriodUnits] <Int32>] [-CRLPeriod] <String>
 [-CRLPeriodUnits] <Int32> [-CRLOverlapPeriod] <String> [-CRLOverlapUnits] <Int32> [-CRLDeltaPeriod] <String>
 [-CRLDeltaPeriodUnits] <Int32> [-CertsValidityPeriod] <String> [-CertsValidityPeriodUnits] <Int32>
 [-InstallWebEnrollment] <Boolean> [-InstallWebRole] <Boolean> [-DoNotLoadDefaultTemplates] <Boolean>
 [[-PreDelaySeconds] <Int32>] [<CommonParameters>]
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

### -AIAHTTPURL01
{{ Fill AIAHTTPURL01 Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 19
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AIAHTTPURL01UploadLocation
{{ Fill AIAHTTPURL01UploadLocation Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 21
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AiaHttpUrl02
{{ Fill AiaHttpUrl02 Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 20
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AiaHttpUrl02UploadLocation
{{ Fill AiaHttpUrl02UploadLocation Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 22
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CACommonName
{{ Fill CACommonName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CAType
{{ Fill CAType Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CDPHTTPURL01
{{ Fill CDPHTTPURL01 Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 27
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CDPHTTPURL01UploadLocation
{{ Fill CDPHTTPURL01UploadLocation Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 29
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CDPHTTPURL02
{{ Fill CDPHTTPURL02 Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 28
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CDPHTTPURL02UploadLocation
{{ Fill CDPHTTPURL02UploadLocation Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 30
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CRLDeltaPeriod
{{ Fill CRLDeltaPeriod Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 38
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CRLDeltaPeriodUnits
{{ Fill CRLDeltaPeriodUnits Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 39
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CRLOverlapPeriod
{{ Fill CRLOverlapPeriod Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 36
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CRLOverlapUnits
{{ Fill CRLOverlapUnits Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 37
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CRLPeriod
{{ Fill CRLPeriod Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 34
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CRLPeriodUnits
{{ Fill CRLPeriodUnits Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 35
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertsValidityPeriod
{{ Fill CertsValidityPeriod Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 40
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertsValidityPeriodUnits
{{ Fill CertsValidityPeriodUnits Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 41
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
{{ Fill ComputerName Description }}

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

### -CpsText
{{ Fill CpsText Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 16
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CpsUrl
{{ Fill CpsUrl Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CryptoProviderName
{{ Fill CryptoProviderName Description }}

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

### -DatabaseDirectory
{{ Fill DatabaseDirectory Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotLoadDefaultTemplates
{{ Fill DoNotLoadDefaultTemplates Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: True
Position: 44
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainName
{{ Fill DomainName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForestAdminPassword
{{ Fill ForestAdminPassword Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ForestAdminUserName
{{ Fill ForestAdminUserName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HashAlgorithmName
{{ Fill HashAlgorithmName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallOCSP
{{ Fill InstallOCSP Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: True
Position: 31
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallWebEnrollment
{{ Fill InstallWebEnrollment Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: True
Position: 42
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallWebRole
{{ Fill InstallWebRole Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: True
Position: 43
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyLength
{{ Fill KeyLength Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogDirectory
{{ Fill LogDirectory Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OCSPHttpUrl01
{{ Fill OCSPHttpUrl01 Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 23
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OCSPHttpUrl02
{{ Fill OCSPHttpUrl02 Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 24
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentCA
{{ Fill ParentCA Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentCALogicalName
{{ Fill ParentCALogicalName Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
{{ Fill Password Description }}

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

### -PreDelaySeconds
{{ Fill PreDelaySeconds Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 45
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseHTTPAia
{{ Fill UseHTTPAia Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: True
Position: 18
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseHTTPCRL
{{ Fill UseHTTPCRL Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: True
Position: 26
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLDAPAIA
{{ Fill UseLDAPAIA Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: True
Position: 17
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLDAPCRL
{{ Fill UseLDAPCRL Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: True
Position: 25
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserName
{{ Fill UserName Description }}

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

### -ValidityPeriod
{{ Fill ValidityPeriod Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 32
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValidityPeriodUnits
{{ Fill ValidityPeriodUnits Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 33
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
