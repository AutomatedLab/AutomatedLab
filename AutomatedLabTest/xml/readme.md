# XML

This is the folder where project XML files go, notably:

 - Format XML
 - Type Extension XML

External help files should _not_ be placed in this folder!

## Notes on Files and Naming

There should be only one format file and one type extension file per project, as importing them has a notable impact on import times.

 - The Format XML should be named `AutomatedLabTest.Format.ps1xml`
 - The Type Extension XML should be named `AutomatedLabTest.Types.ps1xml`

## Tools

### New-PSMDFormatTableDefinition

This function will take an input object and generate format xml for an auto-sized table.

It provides a simple way to get started with formats.

### Get-PSFTypeSerializationData

```
C# Warning!
This section is only interest if you're using C# together with PowerShell.
```

This function generates type extension XML that allows PowerShell to convert types written in C# to be written to file and restored from it without being 'Deserialized'. Also works for jobs or remoting, if both sides have the `PSFramework` module and type extension loaded.

In order for a class to be eligible for this, it needs to conform to the following rules:

 - Have the `[Serializable]` attribute
 - Be public
 - Have an empty constructor
 - Allow all public properties/fields to be set (even if setting it doesn't do anything) without throwing an exception.

```
non-public properties and fields will be lost in this process!
```