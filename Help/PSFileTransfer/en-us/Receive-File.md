---
external help file: PSFileTransfer-help.xml
Module Name: PSFileTransfer
online version:
schema: 2.0.0
---

# Receive-File

## SYNOPSIS
Receives a file from a remote session.

## SYNTAX

```
Receive-File [-SourceFilePath] <String> [-DestinationFilePath] <String> [-Session] <PSSession>
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
$session = New-PsSession leeholmes1c23
```

PS \>Receive-File c:\temp\test.exe c:\temp\test.exe $session

## PARAMETERS

### -SourceFilePath
{{ Fill SourceFilePath Description }}

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

### -DestinationFilePath
{{ Fill DestinationFilePath Description }}

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

### -Session
{{ Fill Session Description }}

```yaml
Type: PSSession
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
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
