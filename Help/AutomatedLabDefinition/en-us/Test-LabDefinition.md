---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version:
schema: 2.0.0
---

# Test-LabDefinition

## SYNOPSIS
Validates the lab definition

## SYNTAX

```
Test-LabDefinition [[-Path] <String>] [-Quiet] [<CommonParameters>]
```

## DESCRIPTION
Use this function to (manually) validate the lab definition before attempting to actually deploy it.
A lot of checks is being done which can potentially avoid issues up front instead of having to wait for these to occur during deployment and perhaps after considerably long time.

## EXAMPLES

### Example 1

```powershell
Test-LabDefinition -Path D:\MyLabs\MyTestLab\Lab.xml
```

Performs validation of the lab saved in the file 'D:\MyLabs\MyTestLab\Lab.xml'

Type        Message                TargetObject     
----        -------                ------------     
Information Role defined           RootDC           
Information Role defined           FirstChildDC     
Information Role defined           DC               
Information Machine defined in lab DC1              
Information Machine defined in lab DC2              
Information Machine defined in lab DC3              
Information Machine defined in lab SRV1             
Information Domain defined         contoso.com      
Information Domain defined         child.contoso.com
Summary     Ok                     Lab              



True

### Example 2

```powershell
Test-LabDefinition -Path D:\MyLabs\MyTestLab\Lab.xml -Quiet
```

Performs validation of the lab saved in the file 'D:\MyLabs\MyTestLab\Lab.xml'.

## PARAMETERS

### -Path
The path to an exported lab definition

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet
Indicates that no console messages should be displayed

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
