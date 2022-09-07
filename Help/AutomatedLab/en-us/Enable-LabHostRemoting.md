---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/Enable-LabHostRemoting
schema: 2.0.0
---

# Enable-LabHostRemoting

## SYNOPSIS
Configures several local policy settings to enable lab host remoting

## SYNTAX

```
Enable-LabHostRemoting [-Force] [-NoDisplay] [<CommonParameters>]
```

## DESCRIPTION
Configures several local policy settings to enable lab host remoting.
These are: SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials, set to 1 SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly, set to 1 SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentials, set to 1 SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowSavedCredentialsWhenNTLMOnly, set to 1 SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters -Name AllowEncryptionOracle, set to 2

## EXAMPLES

### Example 1
```powershell
PS C:\> Enable-LabHostRemoting -Force -NoDisplay
```

Enable all remoting-relevant settings to allow remote management of the lab machines.

## PARAMETERS

### -Force
Do not query user.

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

### -NoDisplay
Do not display console messages

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

