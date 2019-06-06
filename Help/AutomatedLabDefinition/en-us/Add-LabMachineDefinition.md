---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Add-LabMachineDefinition

## SYNOPSIS
{{ Fill in the Synopsis }}

## SYNTAX

### Network (Default)
```
Add-LabMachineDefinition -Name <String> [-Memory <Double>] [-MinMemory <Double>] [-MaxMemory <Double>]
 [-Processors <Int32>] [-DiskName <String[]>] [-OperatingSystem <OperatingSystem>]
 [-OperatingSystemVersion <String>] [-Network <String>] [-IpAddress <String>] [-Gateway <String>]
 [-DnsServer1 <String>] [-DnsServer2 <String>] [-IsDomainJoined] [-DefaultDomain]
 [-InstallationUserCredential <PSCredential>] [-DomainName <String>] [-Roles <Role[]>] [-ProductKey <String>]
 [-UserLocale <String>] [-PostInstallationActivity <PostInstallationActivity[]>] [-ToolsPath <String>]
 [-ToolsPathDestination <String>] [-VirtualizationHost <VirtualizationHost>] [-EnableWindowsFirewall]
 [-AutoLogonDomainName <String>] [-AutoLogonUserName <String>] [-AutoLogonPassword <String>]
 [-AzureProperties <Hashtable>] [-HypervProperties <Hashtable>] [-Notes <Hashtable>] [-PassThru]
 [-FriendlyName <String>] [-SkipDeployment] [-AzureRoleSize <String>] [-TimeZone <String>]
 [-RhelPackage <String[]>] [<CommonParameters>]
```

### NetworkAdapter
```
Add-LabMachineDefinition -Name <String> [-Memory <Double>] [-MinMemory <Double>] [-MaxMemory <Double>]
 [-Processors <Int32>] [-DiskName <String[]>] [-OperatingSystem <OperatingSystem>]
 [-OperatingSystemVersion <String>] [-NetworkAdapter <NetworkAdapter[]>] [-IsDomainJoined] [-DefaultDomain]
 [-InstallationUserCredential <PSCredential>] [-DomainName <String>] [-Roles <Role[]>] [-ProductKey <String>]
 [-UserLocale <String>] [-PostInstallationActivity <PostInstallationActivity[]>] [-ToolsPath <String>]
 [-ToolsPathDestination <String>] [-VirtualizationHost <VirtualizationHost>] [-EnableWindowsFirewall]
 [-AutoLogonDomainName <String>] [-AutoLogonUserName <String>] [-AutoLogonPassword <String>]
 [-AzureProperties <Hashtable>] [-HypervProperties <Hashtable>] [-Notes <Hashtable>] [-PassThru]
 [-FriendlyName <String>] [-SkipDeployment] [-AzureRoleSize <String>] [-TimeZone <String>]
 [-RhelPackage <String[]>] [<CommonParameters>]
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

### -AutoLogonDomainName
{{ Fill AutoLogonDomainName Description }}

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

### -AutoLogonPassword
{{ Fill AutoLogonPassword Description }}

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

### -AutoLogonUserName
{{ Fill AutoLogonUserName Description }}

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

### -AzureProperties
{{ Fill AzureProperties Description }}

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AzureRoleSize
{{ Fill AzureRoleSize Description }}

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

### -DefaultDomain
{{ Fill DefaultDomain Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DiskName
{{ Fill DiskName Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsServer1
{{ Fill DnsServer1 Description }}

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DnsServer2
{{ Fill DnsServer2 Description }}

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
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

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableWindowsFirewall
{{ Fill EnableWindowsFirewall Description }}

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

### -FriendlyName
{{ Fill FriendlyName Description }}

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

### -Gateway
{{ Fill Gateway Description }}

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HypervProperties
{{ Fill HypervProperties Description }}

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InstallationUserCredential
{{ Fill InstallationUserCredential Description }}

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IpAddress
{{ Fill IpAddress Description }}

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IsDomainJoined
{{ Fill IsDomainJoined Description }}

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

### -MaxMemory
{{ Fill MaxMemory Description }}

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Memory
{{ Fill Memory Description }}

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinMemory
{{ Fill MinMemory Description }}

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
{{ Fill Name Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Network
{{ Fill Network Description }}

```yaml
Type: String
Parameter Sets: Network
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetworkAdapter
{{ Fill NetworkAdapter Description }}

```yaml
Type: NetworkAdapter[]
Parameter Sets: NetworkAdapter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Notes
{{ Fill Notes Description }}

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystem
{{ Fill OperatingSystem Description }}

```yaml
Type: OperatingSystem
Parameter Sets: (All)
Aliases: OS

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystemVersion
{{ Fill OperatingSystemVersion Description }}

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

### -PassThru
{{ Fill PassThru Description }}

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

### -PostInstallationActivity
{{ Fill PostInstallationActivity Description }}

```yaml
Type: PostInstallationActivity[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Processors
{{ Fill Processors Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProductKey
{{ Fill ProductKey Description }}

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

### -RhelPackage
{{ Fill RhelPackage Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Roles
{{ Fill Roles Description }}

```yaml
Type: Role[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipDeployment
{{ Fill SkipDeployment Description }}

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

### -TimeZone
{{ Fill TimeZone Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Afghanistan Standard Time, Alaskan Standard Time, Aleutian Standard Time, Altai Standard Time, Arab Standard Time, Arabian Standard Time, Arabic Standard Time, Argentina Standard Time, Astrakhan Standard Time, Atlantic Standard Time, AUS Central Standard Time, Aus Central W. Standard Time, AUS Eastern Standard Time, Azerbaijan Standard Time, Azores Standard Time, Bahia Standard Time, Bangladesh Standard Time, Belarus Standard Time, Bougainville Standard Time, Canada Central Standard Time, Cape Verde Standard Time, Caucasus Standard Time, Cen. Australia Standard Time, Central America Standard Time, Central Asia Standard Time, Central Brazilian Standard Time, Central Europe Standard Time, Central European Standard Time, Central Pacific Standard Time, Central Standard Time, Central Standard Time (Mexico), Chatham Islands Standard Time, China Standard Time, Cuba Standard Time, Dateline Standard Time, E. Africa Standard Time, E. Australia Standard Time, E. Europe Standard Time, E. South America Standard Time, Easter Island Standard Time, Eastern Standard Time, Eastern Standard Time (Mexico), Egypt Standard Time, Ekaterinburg Standard Time, Fiji Standard Time, FLE Standard Time, Georgian Standard Time, GMT Standard Time, Greenland Standard Time, Greenwich Standard Time, GTB Standard Time, Haiti Standard Time, Hawaiian Standard Time, India Standard Time, Iran Standard Time, Israel Standard Time, Jordan Standard Time, Kaliningrad Standard Time, Kamchatka Standard Time, Korea Standard Time, Libya Standard Time, Line Islands Standard Time, Lord Howe Standard Time, Magadan Standard Time, Magallanes Standard Time, Marquesas Standard Time, Mauritius Standard Time, Mid-Atlantic Standard Time, Middle East Standard Time, Montevideo Standard Time, Morocco Standard Time, Mountain Standard Time, Mountain Standard Time (Mexico), Myanmar Standard Time, N. Central Asia Standard Time, Namibia Standard Time, Nepal Standard Time, New Zealand Standard Time, Newfoundland Standard Time, Norfolk Standard Time, North Asia East Standard Time, North Asia Standard Time, North Korea Standard Time, Omsk Standard Time, Pacific SA Standard Time, Pacific Standard Time, Pacific Standard Time (Mexico), Pakistan Standard Time, Paraguay Standard Time, Qyzylorda Standard Time, Romance Standard Time, Russia Time Zone 10, Russia Time Zone 11, Russia Time Zone 3, Russian Standard Time, SA Eastern Standard Time, SA Pacific Standard Time, SA Western Standard Time, Saint Pierre Standard Time, Sakhalin Standard Time, Samoa Standard Time, Sao Tome Standard Time, Saratov Standard Time, SE Asia Standard Time, Singapore Standard Time, South Africa Standard Time, Sri Lanka Standard Time, Sudan Standard Time, Syria Standard Time, Taipei Standard Time, Tasmania Standard Time, Tocantins Standard Time, Tokyo Standard Time, Tomsk Standard Time, Tonga Standard Time, Transbaikal Standard Time, Turkey Standard Time, Turks And Caicos Standard Time, Ulaanbaatar Standard Time, US Eastern Standard Time, US Mountain Standard Time, UTC, UTC+12, UTC+13, UTC-02, UTC-08, UTC-09, UTC-11, Venezuela Standard Time, Vladivostok Standard Time, Volgograd Standard Time, W. Australia Standard Time, W. Central Africa Standard Time, W. Europe Standard Time, W. Mongolia Standard Time, West Asia Standard Time, West Bank Standard Time, West Pacific Standard Time, Yakutsk Standard Time

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ToolsPath
{{ Fill ToolsPath Description }}

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

### -ToolsPathDestination
{{ Fill ToolsPathDestination Description }}

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

### -UserLocale
{{ Fill UserLocale Description }}

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

### -VirtualizationHost
{{ Fill VirtualizationHost Description }}

```yaml
Type: VirtualizationHost
Parameter Sets: (All)
Aliases:
Accepted values: HyperV, Azure, VMWare

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

### System.Management.Automation.SwitchParameter

## OUTPUTS

### AutomatedLab.Machine

## NOTES

## RELATED LINKS
