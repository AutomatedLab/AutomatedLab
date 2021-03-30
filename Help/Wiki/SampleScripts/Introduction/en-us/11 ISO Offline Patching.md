# Introduction - 11 ISO Offline Patching

INSERT TEXT HERE

```powershell
<#
These few lines applies Windows Updates on a Windows installation image.
In order to patch a Windows Installation image, you need to know the image index. In general, a Windows Server ISO file contains 4 images. You can view them using the command

PS C:\> Get-LabAvailableOperatingSystem  -Path E:\LabSources\ISOs\en_windows_server_2012_r2_with_update_x64_dvd_4065220.iso

OperatingSystemName                         Idx Version        PublishedDate        IsoPath
-------------------                         --- -------        -------------        -------
Windows Server 2012 R2 Standard (Server Core Installation)   1   6.3.9600.17031 3/18/2014 1:29:36 PM E:\LabS
Windows Server 2012 R2 Standard (Server with a GUI)       2   6.3.9600.17031 3/18/2014 1:37:34 PM E:\LabS
Windows Server 2012 R2 Datacenter (Server Core Installation) 3   6.3.9600.17031 3/18/2014 1:43:08 PM E:\LabS
Windows Server 2012 R2 Datacenter (Server with a GUI)     4   6.3.9600.17031 3/18/2014 1:50:39 PM E:\LabS

If you want to update the non-code datacenter image, the index would be 4 and the command looks like this:

Update-LabIsoImage -SourceIsoImagePath $labSources\ISOs\en_windows_server_2012_r2_with_update_x64_dvd_4065220.iso `
-TargetIsoImagePath $labSources\ISOs\UpdatedServer2012R2.iso `
-UpdateFolderPath $labSources\OSUpdates\2012R2 `
-SourceImageIndex 4

The script below does is all automatically. It looks for the latest ISO that provides 'Windows Server 2012 R2 Datacenter (Server with a GUI)' and uses the correct index.
#>

$os = Get-LabAvailableOperatingSystem -Path $labSources |
Where-Object OperatingSystemName -EQ 'Windows Server 2012 R2 Datacenter (Server with a GUI)' |
Sort-Object -Property Version -Descending |
Select-Object -First 1

Update-LabIsoImage -SourceIsoImagePath $os.IsoPath `
-TargetIsoImagePath $labSources\ISOs\UpdatedServer2012R2.iso `
-UpdateFolderPath E:\LabSources\OSUpdates\2012R2 `
-SourceImageIndex $os.ImageIndex
```
