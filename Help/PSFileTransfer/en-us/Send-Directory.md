---
external help file: PSFileTransfer-help.xml
Module Name: PSFileTransfer
online version:
schema: 2.0.0
---

# Send-Directory

## SYNOPSIS
Send a directory to a remote session

## SYNTAX

```
Send-Directory [-SourceFolderPath] <Object> [-DestinationFolderPath] <Object> [-Session] <PSSession[]>
 [<CommonParameters>]
```

## DESCRIPTION
Send a directory to a remote session

## EXAMPLES

### Example 1
```powershell
PS C:\> Send-Directory -Source .\data -Destination C:\OnRemote -Session $session
```

Transmits the entire folder data to the destination folder C:\OnRemote

## PARAMETERS

### -DestinationFolderPath
Remote destination

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Session
The session to send to 

```yaml
Type: PSSession[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceFolderPath
Local source path

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
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
