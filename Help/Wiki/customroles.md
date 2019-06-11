# Summary
Adding roles to AutomatedLab was painful and complicated and almost only possible if you know the internals of AutomatedLab and how all the parts are interconnected. The concept of custom roles have been introduced to quickly add new roles to AutomatedLab by just copying some files to the LabSources\CustomRoles folder.


Custom roles can be defined by just one file or can be quite complex. A very simple one that explains all the features of custom roles is the [DemoCustomRole](https://github.com/AutomatedLab/AutomatedLab/wiki/DemoCustomRole). When assigning a custom role to a machine you can specify parameters to make the use flexible.

## The concept in short
### Simple Custom Role
Defining a new custom role is as simple as that:
- Create a new folder in LabSources\CustomRoles named after your role, for example TestRole.
- Create a PS1 file in the newly created folder with the same name (TestRole.ps1).

You are done. Now the AutomatedLab cmdlet Get-LabPostInstallationActivity will pick up that new role when using the parameter CustomRole (if powershell auto-comlete is quick enough and does not time out). That role can be passed to a machine then

```powershell
$role = Get-LabPostInstallationActivity -CustomRole TestRole
Add-LabMachineDefinition -Name TestServer -PostInstallationActivity $role
```

During the deployment, AutomatedLab sends the TestRole folder to the virtual machine and runs the script 'TestRole.ps1' there remotely. This is the most simple implementation. There are no parameters, just a single script and no local activities.

### Running local activities on the host as part of a custom role
Quite often in order to install a role you need some files from the internet but the VMs are not internet connected. For that the custom role feature looks for two scripts in the custom role folder:
- HostStart.ps1 (invoked locally)
- <CustomRoleName>.ps1 (invoked remotely on the VM)
- HostEnd.ps1 (invoked locally)

The HostStart script is run before anything is triggered on the VM and the HostEnd script after the custom role script has been invoked on the VM. It is not mandatory to have all three scripts. You can have a custom role with just a HostStart script running locally and no custom role script or with just a custom role script and nothing that runs on the host. A good example is the MDT custom role.

### Custom Role Parameters
Parameters can be defined as well like this:

```powershell
$role = Get-LabPostInstallationActivity -CustomRole TestRole -Properties @{ param1 = 'Test'; param2 = 100}
```

AutomatedLab will throw an error if the custom role script's parameters do not match the hashtable defined. It also checks for mandatory parameters in the script and throws an error if these are not assigned in the properties hashtable.

If you use HostStart and / or HostEnd scripts, AutomatedLab verifies the properties hashtable against all these scripts. The hashtable will be filtered before invoking the scripts and splatting the parameters. The DemoCustomRole shows this.

### More Complex Custom Role
As AutomatedLab copies the whole folder to the machine the role is assigned to, you can also have a script that calls other scripts. For example TestRole.ps1 could look like this:

```powershell
& $PSScriptRoor\Init.ps1
& $PSScriptRoor\Install.ps1
& $PSScriptRoor\Customizations.ps1
```

The same pattern can be used for HostStart and HostEnd as well. You do not have to put all the logic in just one file.

### Demo Roles
AutomatedLab comes with some some roles.
* [DemoCustomRole](https://github.com/AutomatedLab/AutomatedLab/tree/develop/LabSources/CustomRoles/DemoCustomRole): This is a easy sample that shows how the parameter handling works and how the files are related to each other.
* [MDT](https://github.com/AutomatedLab/AutomatedLab/tree/develop/LabSources/CustomRoles/MDT): This role installs an MDT server. It only comes with a HostStart.ps1 script and does not have a custom role script (MDT.ps1) that is invoked on the lab VM.
* [ProGet5](https://github.com/AutomatedLab/AutomatedLab/tree/develop/LabSources/CustomRoles/ProGet5): This role installs an Inedo ProGet server, also without a custom role script. All the orchestration is done locally on the host.