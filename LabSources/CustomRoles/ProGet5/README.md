# ProGet 5 Custom Role

This role installs [inedo ProGet](https://inedo.com/proget) on the assigned lab VM. The role requires two parameters:
* ProGetDownloadLink (please get the link to the latest version from the inedo website)
* SqlServer (The name of the SQL server for creating the ProGet database on)

The following code block is a sample taken from the script [ProGet Lab - HyperV.ps1](https://github.com/AutomatedLab/AutomatedLab/blob/develop/LabSources/SampleScripts/Scenarios/ProGet%20Lab%20-%20HyperV.ps1). This script can be used to create a ready-to-use environment or as a basis for creating your own customized ProGet environment.

``` PowerShell
$role = Get-LabPostInstallationActivity -CustomRole ProGet5 -Properties @{
    ProGetDownloadLink = 'https://s3.amazonaws.com/cdn.inedo.com/downloads/proget/ProGetSetup5.0.10.exe'
    SqlServer = 'PGSql1'
}
Add-LabMachineDefinition -Name PGWeb1 -Memory 1GB -Roles WebServer -IpAddress 192.168.110.51 -PostInstallationActivity $role
```

## Deployment Details
The custom role does the following tasks
- Downloads and installs .net Framework 4.5.2
- Removes the Web-DAV-Publishing Windows Feature
- Download and installs ProGet (small installer without SQL, requests trial key)
    - The ProGet installation creates the SQL database
- The Domain Admin group gets administrative rights on all ProGet Feeds
- The authentication / user directory in ProGet is changed to Active Directory
- A default feed named 'Internal' is created
- The ProGet service is restarted until the activation was successful.