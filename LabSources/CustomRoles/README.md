# Custom Roles

Store custom roles to be used with Get-PostInstallationActivity here.

Target Structure (Where CustomRoleName1 is the name of your role)

* Directory: CustomRoleName1
    * CustomRoleName1.ps1 (optional, runs on the VM the role is assigned to)
    * HostStart.ps1 (optional, runs first and on the host)
    * HostEnd.ps1 (optional, runs at the end on the host)
    * Additional files and subfolders referenced in the previous scripts (will be copied to the VM the role is assigned to)

For more information please visit the Wiki: [Custom Roles](https://github.com/AutomatedLab/AutomatedLab/wiki/Custom-Roles)