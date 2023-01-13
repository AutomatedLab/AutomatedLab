---
external help file: AutomatedLab-help.xml
Module Name: AutomatedLab
online version: https://automatedlab.org/en/latest/AutomatedLab/en-us/New-LabTfsFeed
schema: 2.0.0
---

# New-LabTfsFeed

## SYNOPSIS
Create new Artifact Feed on lab TFS/Azure DevOps infrastructure

## SYNTAX

```
New-LabTfsFeed [-ComputerName] <String> [-FeedName] <String> [[-FeedPermissions] <Object[]>] [-PassThru]
 [<CommonParameters>]
```

## DESCRIPTION
Create new Artifact Feed on lab TFS/Azure DevOps infrastructure

## EXAMPLES

### Example 1
```powershell
PS C:\> New-LabTfsFeed -ComputerName AZDO001 -FeedName PowerShellInternal -PassThru
```

Create a feed called PowerShellInternal on Azure DevOps host AZDO001

### Example 2
```powershell
$feedPermissions = @()
$feedPermissions += (New-Object pscustomobject -Property @{ role = 'administrator'; identityDescriptor = "System.Security.Principal.WindowsIdentity;$domainSid-1000" })
$feedPermissions += (New-Object pscustomobject -Property @{ role = 'contributor'; identityDescriptor = "System.Security.Principal.WindowsIdentity;$domainSid-513" })
$feedPermissions += (New-Object pscustomobject -Property @{ role = 'contributor'; identityDescriptor = "System.Security.Principal.WindowsIdentity;$domainSid-515" })
$feedPermissions += (New-Object pscustomobject -Property @{ role = 'reader'; identityDescriptor = 'System.Security.Principal.WindowsIdentity;S-1-5-7' })

$powerShellFeed = Get-LabTfsFeed -ComputerName $nugetServer -FeedName PowerShell -ErrorAction SilentlyContinue
if (-not $powerShellFeed)
{
    $powerShellFeed = New-LabTfsFeed -ComputerName $nugetServer -FeedName PowerShell -FeedPermissions $feedPermissions -PassThru -ErrorAction Stop
}
```

Create a feed with individual permissions

## PARAMETERS

### -ComputerName
The lab machine (or reference) hosting the Azure DevOps role

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

### -FeedName
Name of feed

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

### -FeedPermissions
Feed permissions

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Indicates that the created feed should be returned

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

