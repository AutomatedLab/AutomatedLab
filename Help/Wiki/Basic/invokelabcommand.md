PowerShell offers a great way to run code on remote machines by means of the cmdlet Invoke-Command. This cmdlet just needs to get a script block to run and computer names. However, connecting to a lab machine that is not in the same security context requires authentication. Also, double-hop authentication scenarios (CredSsp) need some configuration to work.
Another challenge is making local variables and local functions available to remote PowerShell sessions. In this regards AL as a framework gives you some nice tools that are making PowerShell Remoting even more effective.
Lab environments usually do not share the same namespace or DNS servers. Hence AL comes up with its own name resolution system. It lets you connect to the machines with the short names regardless whether they are hosted on Hyper-V or Azure.  

## Invoke-LabCommand
Invoke-LabCommand is like a proxy. It works pretty similar to Invoke-Command but adds a lot of functionality that makes working in a lab even easier. The next sections are describing each of these additional features with some samples.
### Name Resolution
AL needs to support two different ways of name resolution as it supports labs on the loal Hyper-V and on Windows Azure.
For Hyper-V scenarios AL creates an entry in the LMHosts file. Connecting to Hyper-V VMs created by AL works with the standard naming resolution.
A bit more work is done behind the scenes for VMs hosted on Azure. AL reads the public IP address of the load balancer each machine is connected to and also discovers the public port for WinRM. This information is added to each machine (see AzureConnectionInfo property) and used inside Invoke-LabCommand. Actually the hard work is done inside the cmdlet New-LabPSSession which also caches connections. The cmdlets Enter-LabPSSession and Connect-LabVM are implementing the AL name resolution as well.
Running a command on a specific VM, regardless if it is hosted on Azure or Hyper-V, works like this (Without the PassThru switch, Invoke-LabCommand does not return any data):
``` PowerShell
Invoke-LabCommand -ScriptBlock { Get-Date } -ComputerName Client1 -PassThru
```

Running a command on all lab VMs, regardless if they are hosted on Azure or Hyper-V, works like this:
``` PowerShell
Invoke-LabCommand -ScriptBlock { Get-Date } -ComputerName (Get-LabVM)
```
### Making local variables and functions available remotely
If you have functions and variables defined locally, they are not available in the remote session. With the using scope (PowerShell 3+) you can access local variables in the remote session but it requires changing the code by adding “$using:” to each variable you want to retrieve from the local scope. Hence this code will no longer work locally which makes debugging your code locally on the VM much harder.
Invoke-LabCommand provides the two parameters “Variable” and “Function”. All the variables and functions given here are pushed to the remove session making them available there.
The following sample demonstrates this by having a local function that just returns the value of a local variable. Invoke-LabCommand runs the same code on a remote machine without changing anything.
The code you may run locally:
``` PowerShell
function Foo
{
    "The calue of '`$someVar' is $someVar"
}

$someVar = 123
Foo
```

To run the same code remotely
``` PowerShell
function Foo
{
    "The calue of '`$someVar' is $someVar"
}

$someVar = 123

Invoke-LabCommand -ComputerName Client1 -ScriptBlock { Foo } -Variable (Get-Variable -Name someVar) -Function (Get-Command -Name Foo)
```
### Double-Hop Authentication and CredSsp
Every machine deployed with AL has CredSsp enabled as a CredSsp server. This is like running “Enable-WSManCredSSP -Role Server”. Invoke-LabCommand always tries to make a connection with CredSsp. If this does not work you will see a warning and a connection without CredSsp is tried. This is definitely not a best practice for a production environment but makes life much easier in a lab. Using CredSsp you can create a remote session from a remote session which is extremely helpful when installing or setting up a lab.
For example, reading an AD user account from a remote session does not work without CredSsp as reading data from Active Directory requires and authentication from the remote machine to a domain controller. Inside an AL lab the following code works out of the box.
``` PowerShell
Invoke-LabCommand -ComputerName Web1 -ScriptBlock {
    Get-ADUser -Identity John
}
```
## Transferring modules to machines
Invoke-LabCommand is a comfortable way to run scripts and ScriptsBlocks defined on your host machine in any lab machine. This cmdlet takes care of the authentication and allows you to send variables and functions to the remote machine. But how can you use cmdlets defined in a PowerShell module that exists on your host machine in a lab VM? With Send-ModuleToPSSession we have provided a way to send any PowerShell module available locally to a lab VM. 

Note: This cmdlet makes use of other functions provided within the AutomatedLab framework to copy files to Hyper-V or Azure machines like Send-Directory and what is provided by the [PSFileTransfer]( https://github.com/AutomatedLab/AutomatedLab/tree/master/PSFileTransfer) module.

Send-ModuleToPSSession will try to send the module using SMB first and if this does not work, using the PSSession.
The module will be copied either to the Program Files\WindowsPowerShell\Modules or to the module path of the user used for opening the PSSession, depending of the scope you set: AllUsers, CurrentUser.
There is also a switch to look for all module dependencies and copy them as well.

## Demo (Problem)
The following code block demos the problem. You have a module locally on your machine and have successfully tested some code. Now you want to invoke that code on all lab machines (Azure or Hyper-V) but the module is not there yet.

``` PowerShell
Import-Lab -Name POSH -NoValidation

#works locally
Get-NTFSAccess -Path C:\

#does not work remotely unless the module has been copied to the machines
$vms = Get-LabVM -Role ADDS
Invoke-LabCommand -ScriptBlock { Get-NTFSAccess -Path C:\ } -ComputerName $vms
```

The error is

```
The term 'Get-NTFSAccess' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is 
correct and try again.
    + CategoryInfo          : ObjectNotFound: (Get-NTFSAccess:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
    + PSComputerName        : POSHDC1
 
The term 'Get-NTFSAccess' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is 
correct and try again.
    + CategoryInfo          : ObjectNotFound: (Get-NTFSAccess:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CommandNotFoundException
```

## Demo (Solution)
It requires just one additional line and you can use your local module on the remote machines and this is, how it works:
1. You deploy your lab or import an import an existing one
2. You create a new PSSession to one or more machines
3. You send the module to these sessions
4. Then you can use the module on the lab VM

After using Send-ModuleToPSSession, everything works as desired.

``` PowerShell
Import-Lab -Name POSH -NoValidation

#works locally
Get-NTFSAccess -Path C:\

$vms = Get-LabVM -Role ADDS

#just one line is required to copy the module to the VMs
Send-ModuleToPSSession -Module (Get-Module -Name NTFSSecurity -ListAvailable) -Session (New-LabPSSession -ComputerName $vms)

#now works remotely 
Invoke-LabCommand -ScriptBlock { Get-NTFSAccess -Path C:\ } -ComputerName $vms -PassThru
```
