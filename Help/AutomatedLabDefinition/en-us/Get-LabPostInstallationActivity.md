---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Get-LabPostInstallationActivity
schema: 2.0.0
---

# Get-LabPostInstallationActivity

## SYNOPSIS
Get post-installation activity

## SYNTAX

## DESCRIPTION
Returns a new post-installation activity that can be attached to machines

## EXAMPLES

### Example 1
```powershell
$proGetRole = Get-LabPostInstallationActivity -CustomRole ProGet5 -Properties @{
    ProGetDownloadLink = 'https://s3.amazonaws.com/cdn.inedo.com/downloads/proget/ProGetSetup5.1.23.exe'
    SqlServer          = 'DSCCASQL01'
}
```

Configures the custom role ProGet5 with two role properties.

### Example 2
```powershell
$postInstallActivity = @()
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName 'New-ADLabAccounts 2.0.ps1' -DependencyFolder $labSources\PostInstallationActivities\PrepareFirstChildDomain
$postInstallActivity += Get-LabPostInstallationActivity -ScriptFileName PrepareRootDomain.ps1 -DependencyFolder $labSources\PostInstallationActivities\PrepareRootDomain
Add-LabMachineDefinition -Name POSHDC1 -Memory 512MB -Roles RootDC -IpAddress 192.168.30.10 -PostInstallationActivity $postInstallActivity
```

Create objects in your lab domain: 5995 users, 138 OUs, 138 groups, sites and site links and more.

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

