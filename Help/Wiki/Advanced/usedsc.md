Invoke-LabDSCConfiguration is the counterpart to Inoke-LabCommand. As described in [Running custom commands using Invoke-LabCommand](https://github.com/AutomatedLab/AutomatedLab/wiki/Running-Custom-Commands-using-Invoke-LabCommand), Invoke-LabCommand is a very powerful cmdlet to customize your lab environment after the initial deployment. Invoke-LabDSCConfiguration can be even more powerful if your customizations can be achieved using PowerShell DSC.

Invoke-LabDSCConfiguration offers the same level of comfort as Invoke-LabCommand, maybe even more as it handles also some of the complexities coming with DSC. You do not have to care about authentication, copying resources or configuring the Local Configuration Manager (if in push mode).

> Note: If you are not familiar with DSC, please consult the documentation published on MSDN [Windows PowerShell Desired State Configuration Overview](https://msdn.microsoft.com/en-us/powershell/dsc/overview).

In order to use Invoke-LabDSCConfiguration, you have to define a local configuration on your host machine and you must have the required DSC resources available on your host machine as well. To demonstrate how Invoke-LabDSCConfiguration works, this article features two demos. The first is extremely simple and does not use any non-standard DSC resources. The second is much more complex, uses the [xWebAdministration](https://github.com/PowerShell/xWebAdministration) DSC Resource and configuration data.

## Demo 1
This configuration is just creating a single file with whatever content you define in the configuration data. The MOF file is created locally on the host in \LabSources\DscConfigurations. The MOF file is then pushed to the lab machines specified by the ComputerName parameter and the Local Configuration Manager (LCM) is configured accordingly with default values. The configuration will be applied each 15 minutes on the lab VMs unless you re-configure the LCM or overwrite the configuration.

Import-Lab is used to make the lab data available in a new PowerShell session.

``` PowerShell
Import-lab -Name POSH -NoValidation

configuration Demo1
{
    File TestFile1
    {
        DestinationPath = 'C:\TestFile1.txt'
        Ensure = 'Present'
        Contents = $ConfigurationData.FileContent
    }
}

$ConfigurationData = @{
    AllNodes = @()
    FileContent = '123'
}

Invoke-LabDscConfiguration -Configuration (Get-Command -Name Demo1) `
-ConfigurationData $ConfigurationData -ComputerName poshfs1
```

To re-apply an existing configuration on a lab machine, you can use this command:

``` PowerShell
Invoke-LabDscConfiguration -ComputerName poshfs1 -UseExisting
```

## Demo 2
In next example, a web site is configured on two lab machines using the DSC resource xWebAdministration. Invoke-LabDSCConfiguration pushes the configuration including the DSC resource to all machines specified.

The xWebAdministration DSC resource is required on the host computer. If this is not there, you can install it right from the PowerShell Gallery like this:

``` PowerShell
Install-Module -Name xWebAdministration
```

This demo configuration was taken from the [xWebAdministration](https://github.com/PowerShell/xWebAdministration#creating-the-default-website-using-configuration-data) main page and slightly modified.

> Note: The function Get-DscConfigurationImportedResource is used to discover all the DSC resources used within a configuration so you do not have to care about that.

``` PowerShell
Configuration Sample_xWebsite_FromConfigurationData
{
    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{$_.Role -eq "Web"}.NodeName
    {
        File DemoFile 
        {
            DestinationPath = 'C:\BakeryWebsite\index.html'
            Ensure = 'Present'
            Type = 'File'
            Contents = 'Test Web Site'
            Force = $true
        }
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"

        }

        WindowsFeature IISManagement
        {
            Ensure          = "Present"
            Name            = "Web-Mgmt-Tools"
        }
        
        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = "Present"
            Name            = "Web-Asp-Net45"
        }

        # Stop an existing website (set up in Sample_xWebsite_Default)
        xWebsite DefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = $Node.DefaultWebSitePath
            DependsOn       = "[WindowsFeature]IIS"
        }

        # Copy the website content
        File WebContent
        {
            Ensure          = "Present"
            SourcePath      = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            Recurse         = $true
            Type            = "Directory"
            DependsOn       = "[WindowsFeature]AspNet45"
        }

        # Create a new website
        xWebsite BakeryWebSite
        {
            Ensure          = "Present"
            Name            = $Node.WebsiteName
            State           = "Started"
            PhysicalPath    = $Node.DestinationPath
            DependsOn       = "[File]WebContent"
        }
    }
}

# Content of configuration data file (e.g. ConfigurationData.psd1) could be:
# Hashtable to define the environmental data
$ConfigurationData = @{
    # Node specific data
    AllNodes = @(
       # All the WebServer has following identical information
       @{
            NodeName           = "*"
            WebsiteName        = "FourthCoffee"
            SourcePath         = "C:\BakeryWebsite\"
            DestinationPath    = "C:\inetpub\FourthCoffee"
            DefaultWebSitePath = "C:\inetpub\wwwroot"
       },
       @{
            NodeName           = "poshdc1.contoso.com"
            Role               = "Web"
        },
       @{
            NodeName           = "poshdc2.contoso.com"
            Role               = "Web"
        }
    )
}
# Pass the configuration data to configuration as follows:
#Sample_xWebsite_FromConfigurationData -ConfigurationData $ConfigurationData -OutputPath C:\DscConfigs

Invoke-LabDscConfiguration -Configuration (Get-Command -Name Sample_xWebsite_FromConfigurationData) -ConfigurationData $ConfigurationData -ComputerName poshdc1 
```