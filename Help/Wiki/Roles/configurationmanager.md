# Configuration Manager

To install SCCM/MEMCM in a lab, the built-in role ConfigurationManager can be used. This role builds on the work of [Adam Cook](https://github.com/codaamok)
who has previously created Custom Roles which can still be used as well.

## Parameters

`Get-LabMachineRoleDefinition -Role ConfigurationManager -Syntax` displays the possible settings that a user can make.

- Version: The version to deploy. Defaults to 2103
- Branch: Either CB (default) or TP
- Roles: A comma-separated single string of roles to deploy. Valid roles:
    - None
    - Management Point
    - Distribution Point
    - Software Update Point
    - Reporting Services Point
    - Endpoint Protection Point
- SiteName: Name of the site that is deployed, defaults to AutomatedLab-01
- SiteCode: Three-digit site code, defaults to AL1
- SqlServerName: Use to specify a machine that is part of the lab (!). Defaults to first available SQL server in the lab
- DatabaseName: Name of the DB, defaults to ALCMDB
- WsusContentPath: Path to WSUS content for an update point. Remember to Add-LabDiskDefinition ;)
- AdminUser: Name of administrative account. Automatically created with Lab Domain Credential.


In addition to that, downloading specific versions of config manager requires overriding or creating settings. The built-in
versions that are part of AutomatedLab's configuration system include 1902, 2002 and 2103.

```powershell
# Built-in and pre-configured

Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerWmiExplorer -Value 'https://github.com/vinaypamnani/wmie2/releases/download/v2.0.0.2/WmiExplorer_2.0.0.2.zip'
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl1902CB -Value 'http://download.microsoft.com/download/1/B/C/1BCADBD7-47F6-40BB-8B1F-0B2D9B51B289/SC_Configmgr_SCEP_1902.exe'
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl1902TP -Value 'http://download.microsoft.com/download/1/B/C/1BCADBD7-47F6-40BB-8B1F-0B2D9B51B289/SC_Configmgr_SCEP_1902.exe'
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2002CB -Value "https://download.microsoft.com/download/e/0/a/e0a2dd5e-2b96-47e7-9022-3030f8a1807b/MEM_Configmgr_2002.exe"
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2002TP -Value "https://download.microsoft.com/download/D/8/E/D8E795CE-44D7-40B7-9067-D3D1313865E5/Configmgr_TechPreview2010.exe"
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2103CB -Value "https://download.microsoft.com/download/8/8/8/888d525d-5523-46ba-aca8-4709f54affa8/MEM_Configmgr_2103.exe"
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2103TP -Value "https://download.microsoft.com/download/D/8/E/D8E795CE-44D7-40B7-9067-D3D1313865E5/Configmgr_TechPreview2103.exe"

# To support a fictitious new version 2112 a new setting is necessary
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2112CB -Value "TheUrl" -PassThru | Register-PSFConfig
Set-PSFConfig -Module AutomatedLab -Name ConfigurationManagerUrl2112TP -Value "TheUrl" -PassThru | Register-PSFConfig
```
