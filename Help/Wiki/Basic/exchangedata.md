## Summary
One basic requirement is sending files to a lab machine as well as receiving files. Both is supported by AutomatedLab, for files and also directory trees.
This feature works with Hyper-V VMs as well as Azure VMs.

## How to use it – send
To send a file or directory to a lab machine, only the local source path and the machine name is required. There is no difference whether the machine is on Hyper-V or Azure.
```
Note: Copy-LabFileItem wraps the cmdlets Send-File and Send-Directory,
both define in the PSFileTransfer module.
```

If the target path is not defined, the file or folder will be put in C:\. The parameter ComputerName is an array and data can be copied to a single or multiple machines with a single command.

The following command copies a file to the specified machine trying SMB first and falling back to WinRM.

``` PowerShell
Copy-LabFileItem -Path 'D:\170630 AL' -ComputerName wServer1 -DestinationFolderPath C:\Temp
```

The following samples are Using the PSFileTransfer cmdlets directly. These do not support SMB and send the files over the PSSession right away. The Force switch creates the target folder if not already existing.
```
Note: It is recommended to use Copy-LabFileItem as SMB is much faster
then sending a byte array over WinRM.
```

``` PowerShell
$s = New-LabPSSession LabVM1
Send-File -SourceFilePath D:\Untitled1.ps1 -DestinationFolderPath C:\Temp\Untitled1.ps1 -Session $s -Force
Send-Directory -SourceFolderPath D:\Test -DestinationFolderPath C:\Windows -Session $s
```

## How to use it – receive
This also works the other way around. If some process creates files on a lab machine that are required for another process on another lab machine, you can retrieve and re-send the file to another machine.

For example, this process is used in the AutomatedLab’s certificate functions like Get-LabCAInstallCertificates.

``` PowerShell
Receive-File -SourceFilePath C:\Unattend.xml -DestinationFilePath D:\Unattend.xml -Session $s
Receive-Directory -SourceFolderPath 'C:\Program Files\Wireshark' -DestinationFolderPath D:\Wireshark -Session $s
```
## Internals
Hyper-V machines are usually reachable from the host by SMB. However, it is not sure or pretty unlikely if the other way works as well, accessing the host machines from the VM.

Copy-LabFileItem always tries SMB first. If this does not work, it uses the PowerShell session and transfers the file as a Byte[]. Reading and writing a file as a byte array, serializing the by byte array and sending it over the network is much slower than SMB but totally sufficient for most scenarios. If you transfer large files, make sure SMB works from the host to the VMs.

```
Note: All the functions of the module PSFileTransfer do not rely on other modules
of AutomatedLab and can be used separately.
```