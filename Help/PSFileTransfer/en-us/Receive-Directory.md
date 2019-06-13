---
external help file: PSFileTransfer-help.xml
Module Name: PSFileTransfer
online version:
schema: 2.0.0
---

# Receive-Directory

## SYNOPSIS
Receive a directory from a remote session

## SYNTAX

```
Receive-Directory [-SourceFolderPath] <Object> [-DestinationFolderPath] <Object> [-Session] <PSSession>
 [<CommonParameters>]
```

## DESCRIPTION
Receive a directory from a remote session

## EXAMPLES

### Example 1
```powershell
PS C:\> Receive-Directory -SourceFolderPath C:\DeployDebug -DestinationFolderPath D:\Temp -Session $session
```

Transmit the folder C:\DeployDebug from the session to the local path D:\Temp

## PARAMETERS

### -DestinationFolderPath
Local destination

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
Session to receive from

```yaml
Type: PSSession
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SourceFolderPath
Remote source

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
