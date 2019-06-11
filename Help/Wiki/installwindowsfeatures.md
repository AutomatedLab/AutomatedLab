## Summary
A quite common task in a lab is to add Windows features to one or some machines. This can be easily done using the cmdlet Install-WindowsFeature that is available since Windows Server 2008 R2. It is also quite easy to the cmdlet on another machine by using Install-WindowsFeature inside a scriptblock that you invoke on a remote machine using Invoke-Command. However, this requires authentication, createing the scripblock and other things. The cmdlet Install-LabWinowsFeature does this all for you.

### Installing Windows Features using Install-LabWindowsFeature
Install-LabWindowsFeature uses Invoke-LabCommand that is discussed in <TODO>. As Invoke-LabCommand handles obstacles like name resolution and authentication with the standard lab account, which makes this task even easier.
The following command installs the Remote Sever Administration tools (RSAT) on the machines Server1 and Server2:

``` PowerShell
Install-LabWindowsFeature -FeatureName RSAT -ComputerName 'server1', 'server2' -IncludeAllSubFeature 
```
It is also possible to push the activity into the background using the AsJob switch. You can start the installation on multiple machines and then wait for the jobs to complete. 

If AsJob is used along with PassThru, Install-LabWindowsFeature returns the job objects. If just PassThru is used, the cmdlet return the result of the feature installation.

``` PowerShell
$jobs = Install-LabWindowsFeature -FeatureName RSAT -ComputerName 'server1', 'server2' -IncludeAllSubFeature -AsJob -PassThru
$result = Wait-LWLabJob -Job $jobs -ProgressIndicator 10 -NoDisplay -PassThru
```
