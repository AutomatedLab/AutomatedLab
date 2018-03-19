# Tools folder

The tools folder is a very comfortable way to distribute your favourite tools to all lab VMs. When you use the ToolsPath parameter, the content
of the given folder will be coped to the machine in C:\Tools. 

``` PowerShell
Add-LabMachineDefinition -Name Server1 -Memory 1GB -ToolsPath $labSources\Tools
```

Of course you can reference any folder you want. AutomatedLab internally uses this standard folder.

If all machines should get the same tools, you can put the parameter ToolsPath value in $PSDefaultParameterValues

``` PowerShell
$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:ToolsPath'= "$labSources\Tools"
}
```