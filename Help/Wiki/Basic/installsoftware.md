## Summary
Installing software on lab machines is almost as easy as installing <TODO Windows Features>.  And there are similar challenges. But additionally, there to the challenges some installers have an extra demand, like the .net 4.5.2 package that cannot be installed remotely. Like for installing Windows Features AutomatedLab tries to provide a solution that makes this task as simple as possible. It does not matter if the **installation file is already on the VM or on your host machine**. And you do not have to care whether it is a **.exe, .msi or .msu** file, AL will handle the complexity for you. And there is also a very convenient way to work **install stuff from ISOs** mounted to the lab VMs.

### Install-LabSoftwarePackage Introduction
The cmdlet that handles the installation is Install-LabSoftwarePackage. It is designed to work in various scenarios that will be discussed in this article.
Internally, it uses Invoke-LabCommand again to connect to the lab VMs by using the credentials known to the lab. The files are copied to the lab VMs using Copy-LabFileItem.

### Install-LabSoftwarePackage Usage
#### Insalling an package that is on the host machine
A very simple demonstration of how the cmdlet can help, is installing Notepad++ on a lab VM. Note that $labSources always points to the LabSources folder that is created by AL, so you do not have to provide the full path. This also works on Azure. A lab VM hosted on Azure accesses the share hosted on Azure by default. The Azure LabSources share can be synced with the local one.
The next command copes the Notepad++.exe file to the VM and invokes the installer. The package must support a silent installation. For Notepad++, you can switch to the silent mode by providing the argument “/S” (case-sensitive).
``` PowerShell
Install-LabSoftwarePackage -ComputerName Server1 -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
```
If you want to install the same package to all machines in a lab, regardless if they run on Hyper-V or Azure, just change the ComputerName parameter:
``` PowerShell
Install-LabSoftwarePackage -ComputerName (Get-LabVM) -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S
```
#### Installing a package that is on the host machine as scheduled job
Some software packages are creating headaches, like the .net Framework 4.5.2. The package calls the Windows Update Service which checks if it is called from remote by checking the token for the NETWORK RID, and cancels the installation if that’s the case.
Install-LabSoftwarePackage offers the switch AsScheduledJob to be able to start the installation remotely which then actually runs locally.
The next example shows how to install .net 4.5.2 on a VM, restart the VM and then install the Windows Management Framework 5.1.

``` PowerShell
Install-LabSoftwarePackage -Path $labSources\SoftwarePackages\NDP452-KB2901907-x86-x64-AllOS-ENU.exe -CommandLine '/q /log c:\dotnet452.txt' -ComputerName Client7 -AsScheduledJob -UseShellExecute
Restart-LabVM -ComputerName Client7 -Wait

Install-LabSoftwarePackage -Path $labSources\V5\Win7AndW2K8R2-KB3134760-x64.msu -ComputerName Client7
Restart-LabVM -ComputerName Client7 -Wait
```

#### Installing a package that is already on the VM
Installing software packages that are already on the VM is also possible. In this case, you can use the LocalPath parameter instead of the Path parameter.

The following command installs the Redgate Reflector on all machines with the role visual studio, expecting the package already to be at C:\. The AsJob switch puts the work into the background.
``` PowerShell
Install-LabSoftwarePackage -LocalPath C:\ReflectorInstaller.exe -CommandLine '/qn /IAgreeToTheEula' -ComputerName (Get-LabMachine -Role VisualStudio2015) -AsJob
```
#### Installing Files from ISO Files mounted to lab VMs.
The cmdlet Install-LabSoftwarePackage is even more effective when combined with other cmdlets AutomatedLab provides. When mounting an ISO into a VM, it is not guaranteed that the ISO will get always the same drive letter. If a lab VM has only one drive, the ISO will be pretty likely drive D:, but if the lab VM has more than one disk attached, things are getting more complex.
Mount-LabIsoImage returns the drive an ISO file actually has inside the VM. This information can be used to construct the path to call. This is demoed in the next example.
``` PowerShell
$drive = Mount-LabIsoImage -ComputerName Web1 -IsoPath $labSources\ISOs\SkypeForBusiness2015.iso -PassThru
Install-LabSoftwarePackage -ComputerName Web1 -LocalPath "$($drive.DriveLetter)\Setup.exe" -CommandLine /BootStrap
Dismount-LabIsoImage -ComputerName Web1
```

For further help and details on the available parameters please call Get-Help Install-LabSoftwarePackage.
