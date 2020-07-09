# Installation

There are two options installing AutomatedLab:

- You can use the [MSI installer](https://github.com/AutomatedLab/AutomatedLab/releases) published on GitHub.
- Or you install from the [PowerShell Gallery](https://www.powershellgallery.com/packages/AutomatedLab/) using the cmdlet Install-Module.  
    **Please note that this is the ONLY way to install AutomatedLab and its dependencies in PowerShell Core/PowerShell 7 on both Windows and Linux/Azure Cloud Shell**

## From gallery
```powershell
Install-PackageProvider Nuget -Force
Install-Module AutomatedLab -AllowClobber

# If you are on Linux and are not starting pwsh with sudo
# This needs to executed only once per user - adjust according to your needs!
Set-PSFConfig -Module AutomatedLab -Name LabAppDataRoot -Value /home/youruser/.alConfig -PassThru | Register-PSFConfig

# Prepare sample content - modify to your needs
# Windows
New-LabSourcesFolder -Drive C

# Linux
Set-PSFConfig -Module AutomatedLab -Name LabSourcesLocation -Value /home/youruser/labsources -PassThru | Register-PSFConfig
New-LabSourcesFolder # Linux
```

## From MSI
AutomatedLab (AL) is a bunch of PowerShell modules. To make the installation process easier, it is provided as an MSI.

Download Link: https://github.com/AutomatedLab/AutomatedLab/releases

There are not many choices when installing AL.

![Install1](https://cloud.githubusercontent.com/assets/11280760/19437688/c01dce38-9476-11e6-8981-d3175d0251e2.png)

The options Typical and Complete are actually doing the same and install AL to the default locations. The PowerShell modules go to "C:\Program Files\WindowsPowerShell\Modules", the rest to "C:\LabSources".

As LabSources can grow quite big, you should go for a custom installation and put this component on a disk with enough free space to store the ISO files. This disk does not have to be an SSD. Do not change the location of the modules unless you really know what you are doing.

![Install2](https://cloud.githubusercontent.com/assets/11280760/19437729/eef3e706-9476-11e6-9b16-982bd069f88d.png)

Very important to AL is the LabSources folder that should look like this:

![Install3](https://cloud.githubusercontent.com/assets/11280760/19438445/5256c3ba-947a-11e6-85b1-68ecc667e59b.png)

If all that worked you are ready to go for [Getting Started](https://github.com/AutomatedLab/AutomatedLab/wiki/2.-Getting-Started).

