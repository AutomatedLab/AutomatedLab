# Running AutomatedLab on a Hyper-V Cluster

While AutomatedLab was not designed to work with CIM sessions, you can install AutomatedLab on one or more cluster nodes.

To use AutomatedLab on a clustered Hyper-V, e.g. an S2D cluster, go about the configuration like you normally would!
The main difference is: Your VM path should now be a CSV (cluster-shared volume), and it is probably a good
idea to store your ISO files either on a network share or in another CSV.

```powershell
New-LabDefinition -Name IsOnCluster -DefaultVirtualizationEngine HyperV -VmPath C:\ClusterStorage\ALVMS

Add-LabVirtualNetworkDefinition -Name ClusterNet -AddressSpace 172.16.0.0/24 -HyperVProperties @{SwitchType = 'External'; AdapterName = 'eth0'}
Add-LabMachineDefinition -Name test -Memory 4GB -OperatingSystem 'Windows Server 2019 Datacenter' -Network ClusterNet -IpAddress 172.16.0.199
Install-Lab
```

All lab VMs will automatically be added as a cluster role, and removed properly when the lab or the VM is removed.
To disable this behavior, the setting `DoNotAddVmsToCluster` has been added. To change this setting:

```powershell
# Disable auto-add
Set-PSFConfig -FullName AutomatedLab.DoNotAddVmsToCluster -Value $true -PassThru | Register-PSFConfig
# Enable auto-add - default
Set-PSFConfig -FullName AutomatedLab.DoNotAddVmsToCluster -Value $false -PassThru | Register-PSFConfig
```

Activities like live migrations depend on your configuration of course. You will not be able to live-migrate
a VM that is connected to internal switches - the rules still apply ;)
