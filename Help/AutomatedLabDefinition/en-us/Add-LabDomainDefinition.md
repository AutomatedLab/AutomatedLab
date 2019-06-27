---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Add-LabDomainDefinition

## SYNOPSIS
Add a definition of an Active Directory domain or forest to the lab

## SYNTAX

```
Add-LabDomainDefinition [-Name] <String> [-AdminUser] <String> [-AdminPassword] <String> [-PassThru]
 [<CommonParameters>]
```

## DESCRIPTION
Adds a definition of an Active Directory domain or forest name together with username which will be the administrator of the domain as well as the password.
This information is used for AutomatedLab to be able to logon to all machines during and after deployment using domain credentials when needed.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-LabDomainDefinition -Name comtoso.com -AdminUser Install -AdminPassword Somepass1
PS C:\> Set-LabInstallationCredential -User Install -Password Somepass1
```

Configures the contoso domain for the entire lab. Take care to select the same installation credentials,
otherwise the domain controller deployment will not work.

## PARAMETERS

### -Name
Name of Active Directory domain or forest in FQDN format.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AdminUser
Desired username of the administrator when deploying a new lab or existing user of the administrator if adding to a lab or an existing external (not deployed by AutomatedLab) domain.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AdminPassword
Desired password of the administrator when deploying a new lab or password of an existing administrator if adding to a lab or an existing external (not deployed by AutomatedLab) domain.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PassThru
Whether or not to return the actual created domain definition in the call of this function to enable you to continue working on a pipeline

```yaml
Type: SwitchParameter
Parameter Sets: (All)
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
