---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/Get-LabInstallationActivity
schema: 2.0.0
---

# Get-LabInstallationActivity

## SYNOPSIS
Get pre/post-installation activity

## SYNTAX

### FileContentDependencyLocalScript
```
Get-LabInstallationActivity -DependencyFolder <String> [-KeepFolder] -ScriptFilePath <String>
 [-Variable <PSVariable[]>] [-Function <FunctionInfo[]>] [-DoNotUseCredSsp] [-CustomRole <String>]
 [<CommonParameters>]
```

### FileContentDependencyRemoteScript
```
Get-LabInstallationActivity -DependencyFolder <String> [-KeepFolder] -ScriptFileName <String>
 [-Variable <PSVariable[]>] [-Function <FunctionInfo[]>] [-DoNotUseCredSsp] [-CustomRole <String>]
 [<CommonParameters>]
```

### IsoImageDependencyLocalScript
```
Get-LabInstallationActivity -IsoImage <String> -ScriptFilePath <String> [-Variable <PSVariable[]>]
 [-Function <FunctionInfo[]>] [-DoNotUseCredSsp] [-CustomRole <String>] [<CommonParameters>]
```

### IsoImageDependencyRemoteScript
```
Get-LabInstallationActivity -IsoImage <String> -ScriptFileName <String> [-Variable <PSVariable[]>]
 [-Function <FunctionInfo[]>] [-DoNotUseCredSsp] [-CustomRole <String>] [<CommonParameters>]
```

### CustomRole
```
Get-LabInstallationActivity [-KeepFolder] [-Properties <Hashtable>] [-Variable <PSVariable[]>]
 [-Function <FunctionInfo[]>] [-DoNotUseCredSsp] [-CustomRole <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns a new pre/post-installation activity that can be attached to machines

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

### -CustomRole
Instead of a regular script, add this as a custom role. Custom roles adhere to a specific
format. For more information, just have a look at $labsources\CustomRoles

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

### -DependencyFolder
A folder of dependency files if necessary

```yaml
Type: String
Parameter Sets: FileContentDependencyLocalScript, FileContentDependencyRemoteScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DoNotUseCredSsp
Indicates that CredSSP should not be used for connections. Useful in existing environments
that you connected to with -SkipDeployment

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

### -Function
A list of functions that will be used inside your Installation Activity

```yaml
Type: FunctionInfo[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsoImage
The ISO image that should be mounted during post-installation

```yaml
Type: String
Parameter Sets: IsoImageDependencyLocalScript, IsoImageDependencyRemoteScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeepFolder
Indicates that the target folder should be kept on the machine

```yaml
Type: SwitchParameter
Parameter Sets: FileContentDependencyLocalScript, FileContentDependencyRemoteScript, CustomRole
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Properties
The hashtable of properties for your custom role, if a custom role was selected.
Bear in mind that this is a Dictionary\<string,string\>, and requires your input
to consist of strings only.

```yaml
Type: Hashtable
Parameter Sets: CustomRole
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptFileName
The remote script file name

```yaml
Type: String
Parameter Sets: FileContentDependencyRemoteScript, IsoImageDependencyRemoteScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptFilePath
The script file path of the script that is executed

```yaml
Type: String
Parameter Sets: FileContentDependencyLocalScript, IsoImageDependencyLocalScript
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Variable
A list of variables that are used in your Installation Activity

```yaml
Type: PSVariable[]
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

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS

