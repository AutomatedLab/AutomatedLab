# SharePoint Server

The roles SharePoint2013, SharePoint2016 and SharePoint2019 enable you to install SharePoint in a single server configuration.
All preqrequisites are downloaded automatically, but can be prepared easily in an offline scenario.

In order to really deploy SharePoint according to your needs, consider using [SharePointDsc](https://github.com/dsccommunity/SharePointDsc) with ```Invoke-LabDscConfiguration```.

## Prerequisites

We store a list of prerequisites with PSFramework, which means that you can customize this setting or use it to download
and prepare the prerequisites! To do that, you can find a list of URIs with ```Get-LabConfigurationItem SharePoint2016Prerequisites # Adjust to your version```.

Simply store the downloaded files without renaming them in ```$labsources\SoftwarePackages\SharePoint2016 # Adjust to your version```. All files are picked up automatically even when no connection is available.