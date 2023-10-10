---
external help file: AutomatedLabDefinition-help.xml
Module Name: AutomatedLabDefinition
online version: https://automatedlab.org/en/latest/AutomatedLabDefinition/en-us/New-LabDefinition
schema: 2.0.0
---

# New-LabDefinition

## SYNOPSIS
Creates a new lab definition

## SYNTAX

```
New-LabDefinition [[-Name] <String>] [[-VmPath] <String>] [[-ReferenceDiskSizeInGB] <Int32>]
 [[-MaxMemory] <Int64>] [[-Notes] <Hashtable>] [-UseAllMemory] [-UseStaticMemory]
 [[-DefaultVirtualizationEngine] <String>] [-Passthru] [<CommonParameters>]
```

## DESCRIPTION
Needed for defining a lab definition which is a mandatory 'container' for the lab to be deployed.
To be called before any other function of AutomatedLab.

## EXAMPLES

### Example 1
```powershell
New-LabDefinition -Name MyTestLab1
```

Creates a new lab definition with the name MyTestLab1

### Example 2
```powershell
New-LabDefinition -Name MyTestLab1 -DefaultVirtualizationEngine HyperV
```

Creates a new lab definition with the name MyTestLab1 and instructs AutomatedLab that all machines being added to the lab, is to be Hyper-V based machines unless anything else is specified using the -VirtualizationHost parameter on Add-LabMachineDefinition.

### Example 3
```powershell
New-LabDefinition -Name MyTestLab1 -DefaultVirtualizationEngine Azure
```

Creates a new lab definition with the name MyTestLab1 and instructs AutomatedLab that all machines being added to the lab, is to be Azure based machines unless anything else is specified using the -VirtualizationHost parameter on Add-LabMachineDefinition.

### Example 4
```powershell
New-LabDefinition -Name MyTestLab1 -DefaultVirtualizationEngine HyperV -VmPath D:\VMs
```

Creates a new lab definition with the name MyTestLab1 and instructs AutomatedLab that all machines being added to the lab, is to be Hyper-V based machines unless anything else is specified using the -VirtualizationHost parameter on Add-LabMachineDefinition.

### Example 5
```powershell
New-LabDefinition -Name MyTestLab1 -DefaultVirtualizationEngine HyperV -MaxMemory 8GB
```

Creates a new lab definition with the name MyTestLab1 and instructs AutomatedLab that all machines being added to the lab, is to be Hyper-V based machines unless anything else is specified using the -VirtualizationHost parameter on Add-LabMachineDefinition.

If 8GB of memory if more than 80% of the available memory, the memory will be limited to 8GB for the entire lab where the machines will split these 8GB in a weighted approach based on what role(s) the machines are to have.
This is only true if the memory is NOT specified when defining machine using Add-LabMachineDefinition.

### Example 6
```powershell
New-LabDefinition -Name MyTestLab1 -DefaultVirtualizationEngine HyperV -UseAllMemory
```

Creates a new lab definition with the name MyTestLab1 and instructs AutomatedLab that all machines being added to the lab, is to be Hyper-V based machines unless anything else is specified using the -VirtualizationHost parameter on Add-LabMachineDefinition.

80% of all available memory will be used for the entire lab where the machines will split this memory in a weighted approach based on what role(s) the machines are to have.
This is only true if the memory is NOT specified when defining machine using Add-LabMachineDefinition.

### Example 7
```powershell
New-LabDefinition -Name MyTestLab1 -DefaultVirtualizationEngine HyperV -UseStaticMemory
```

Creates a new lab definition with the name MyTestLab1 and instructs AutomatedLab that all machines being added to the lab, is to be Hyper-V based machines unless anything else is specified using the -VirtualizationHost parameter on Add-LabMachineDefinition.

All machines will be using static memory as opposed the default dynamic memory.

## PARAMETERS

### -DefaultVirtualizationEngine
Virtualization engine to use as default for the lab.
When not specifying the -VirtualizationHost parameter

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Azure, HyperV, VMWare

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxMemory
Maximum memory to use for lab if using automatic configuration of memory for each machine (by not specifying the memory at all)

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Name of lab.
Name must only contain character a-z, A-Z and 0-9.

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

### -Notes
Notes to add to the lab

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Passthru
Indicates that the created definition should also be returned

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

### -ReferenceDiskSizeInGB
Specifies the size of the base disk to create for each used Operating System

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 50
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseAllMemory
Instructs AutomatedLab to use 80% of all available memory for the lab where the machines will split this memory in a weighted approach based on what role(s) the machines are to have.
This is only true if the memory is NOT specified when defining machine using Add-LabMachineDefinition.

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

### -UseStaticMemory
Instructs AutomatedLab to only configure static memory for all machines if using automatic configuration of memory for each machine (by not specifying the memory at all).

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

### -VmPath
Path of placement of Hyper-V based machines

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### None
## NOTES

## RELATED LINKS

