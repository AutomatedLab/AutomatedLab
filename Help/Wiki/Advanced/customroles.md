# Summary

Adding native roles to AutomatedLab requires modification of the class library in addition to modifying the PowerShell Code to include a new role. As this is not very user-friendly, the concept of custom roles has been introduced.

Using custom roles, you can quickly add new roles to AutomatedLab by just copying some files to the LabSources\CustomRoles folder. These modifications do not require forking and updating AutomatedLab, and can be done using just PowerShell.

Custom roles can be anything from a simple script running on the lab VMs to a complex orchestration running on the lab host as well as the guests. A very simple example that explains all the features of custom roles is the [DemoCustomRole](https://github.com/AutomatedLab/AutomatedLab/tree/master/LabSources/CustomRoles/DemoCustomRole).

At the moment, the following custom roles exist:
- CM-2002, CM-1902 to deploy System Center Configuration Manager
- LabBuilder to deploy a REST API using polaris on a nested Hyper-V which can be used to deploy labs
- MDT
- Exchange2016, Exchange2019 to deploy the respective Exchange version
- NuGetServer to deploy a simple ASP.NET page that includes the NuGet.Server package
- PowerShellWebAccess to enable PowerShell Web Access (PSWA) on a VM
- ProGet5 to install Inedo ProGet

## The concept in short
### Simple Custom Role
Defining a new custom role is as simple as that:
- Create a new folder in `LabSources\CustomRoles` named after your role, for example `TestRole`.
- Create a PS1 file in the newly created folder with the same name as the folder, for example `TestRole.ps1`.

You are done. Now the AutomatedLab cmdlet `Get-LabInstallationActivity` will pick up that new role when using the parameter CustomRole (if PowerShell auto-complete is quick enough and does not time out). That role can be passed to a machine then:

```PowerShell
$role = Get-LabInstallationActivity -CustomRole TestRole
Add-LabMachineDefinition -Name TestServer -PostInstallationActivity $role
```

During the deployment, AutomatedLab sends the TestRole folder to the virtual machine and runs the script `TestRole.ps1` there remotely. This is the most simple implementation. There are no parameters, just a single script and no local activities.

### Custom Role Parameters
Parameters can be defined as well like this:

```PowerShell
$role = Get-LabInstallationActivity -CustomRole TestRole -Properties @{ param1 = 'Test'; param2 = 100}
```

AutomatedLab will throw an error if the custom role script's parameters do not match the hashtable defined. It also checks for mandatory parameters in the script and throws an error if these are not assigned in the properties hashtable.

If you use HostStart and / or HostEnd scripts, AutomatedLab verifies the properties hashtable against all these scripts. The hashtable will be filtered before invoking the scripts and splatting the parameters. The DemoCustomRole shows this.

### Passing along variables and functions

If role parameters are not enough, remember that you can also use the parameters `Variable` and `Function` with `Get-LabInstallationActivity` in order
to send variables and functions to your remote machines. Just keep in mind that those are used only for the VMs, and not in the HostStart and HostEnd scripts. Since roles
are executed in the context of a lab, the script-scoped variable `$data` is available and contains the entire lab's information.

```powershell
# Role Definition
$role = Get-LabInstallationActivity -CustomRole TestRole -Variable (Get-Variable -Name var1,var2,var3) -Function (Get-Command -Name Get-StringSection)

# Sample content in TestRole.ps1
Write-Host "Deserialized content of `$var1: $var1"
Write-Host "Function result: $((Get-StringSection aabbcc 2) -join '-')"
```

### Running local activities on the host as part of a custom role
Quite often in order to install a role you need some files from the internet but the VMs are not internet connected. For that the custom role feature looks for two scripts in the custom role folder:
- HostStart.ps1 (invoked locally)
- <CustomRoleName>.ps1 (invoked remotely on the VM)
- HostEnd.ps1 (invoked locally)

The HostStart script is run before anything is triggered on the VM and the HostEnd script after the custom role script has been invoked on the VM. It is not mandatory to have all three scripts. You can have a custom role with just a HostStart script running locally and no custom role script or with just a custom role script and nothing that runs on the host. A good example is the MDT custom role.

When using locally-executed scripts, make good use of the helpful AutomatedLab cmdlets:
- `Get-Lab` retrieves information about a running (imported) lab
- `Get-LabVm` retrieves VM objects - allthough most of our cmdlets can work with VM names as well
- `Get-LabInternetFile` and `Install-LabSoftwarePackage` to download and install content within your role
- `Invoke-LabDscConfiguration` to configure VMs using DSC for even more elaborate scenarios

### More Complex Custom Role
As AutomatedLab copies the whole folder to the machine the role is assigned to, you can also have a script that calls other scripts. For example TestRole.ps1 could look like this:

```PowerShell
& $PSScriptRoot\Init.ps1
& $PSScriptRoot\Install.ps1
& $PSScriptRoot\Customizations.ps1
```

### Custom Role Tests
Pester tests are now available for Custom Roles! Use `New-LabPesterTest` to create the stub test harness like this:

```PowerShell
New-LabPesterTest -Role MyCustomRole -IsCustomRole -Path $global:LabSources\CustomRoles\MyCustomRole
```

The same pattern can be used for HostStart and HostEnd as well. You do not have to put all the logic in just one file.

### Demo Roles
AutomatedLab comes with some some roles.
* [DemoCustomRole](https://github.com/AutomatedLab/AutomatedLab/tree/develop/LabSources/CustomRoles/DemoCustomRole): This is a easy sample that shows how the parameter handling works and how the files are related to each other.
* [MDT](https://github.com/AutomatedLab/AutomatedLab/tree/develop/LabSources/CustomRoles/MDT): This role installs an MDT server. It only comes with a HostStart.ps1 script and does not have a custom role script (MDT.ps1) that is invoked on the lab VM.
* [ProGet5](https://github.com/AutomatedLab/AutomatedLab/tree/develop/LabSources/CustomRoles/ProGet5): This role installs an Inedo ProGet server, also without a custom role script. All the orchestration is done locally on the host.
