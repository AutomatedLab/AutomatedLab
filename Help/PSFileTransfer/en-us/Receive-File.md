---
external help file: PSFileTransfer-help.xml
Module Name: PSFileTransfer
online version: https://automatedlab.org/en/latest/PSFileTransfer/en-us/Receive-File
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
Receive files from remote hosts

## EXAMPLES

### EXAMPLE 1
```powershell
$session = New-PsSession leeholmes1c23
Receive-File c:\temp\test.exe c:\temp\test.exe $session
```

Receives the file test.exe from the remote session

## PARAMETERS

### -DestinationFilePath
Local destination file name

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

### -Session
The session to transmit from

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

### -SourceFilePath
Remote source file name

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

