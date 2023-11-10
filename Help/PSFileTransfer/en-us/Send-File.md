---
external help file: PSFileTransfer-help.xml
Module Name: PSFileTransfer
online version: https://automatedlab.org/en/latest/PSFileTransfer/en-us/Send-File
schema: 2.0.0
---

# Send-File

## SYNOPSIS
Sends a file to a remote session.

## SYNTAX

```
Send-File [-SourceFilePath] <String> [-DestinationFolderPath] <String> [-Session] <PSSession[]> [-Force]
 [<CommonParameters>]
```

## DESCRIPTION
Sends a file to a remote session.

## EXAMPLES

### EXAMPLE 1
```powershell
$session = New-PsSession leeholmes1c23
Send-File c:\temp\test.exe c:\temp\test.exe $session
```

Sends the file test.exe to a remote session

## PARAMETERS

### -DestinationFolderPath
The remote destination path

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

### -Force
Indicates that existing files will be overwritten

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

### -SourceFilePath
The local source path

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

