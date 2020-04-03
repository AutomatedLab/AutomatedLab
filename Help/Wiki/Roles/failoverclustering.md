# Failover Clustering
More and more roles support failover clusters. Thus, testing e.g. SQL AlwaysOn and other scenarios is something that you will need a cluster for. AutomatedLab 4.5 and newer is able to deploy one or more clusters for you. Depending on the OS version, you are able to deploy multidomain or workgroup clusters as well, without any work on your part except for selecting two or more machines.  
## Cluster  
AutomatedLab can help you set up one or more failover clusters starting with Server 2008 R2. All you need to do is select the role FailoverNode for at least two of your machines.  

```powershell
# Simple cluster with auto-generated name ALCluster and auto-generated IP
Add-LabMachineDefinition -Name focln1 -Roles FailoverNode
Add-LabMachineDefinition -Name focln2 -Roles FailoverNode
```  
The role properties allow you to customize your cluster and to create more than one cluster.  
```powershell
# Two clusters
$cluster1 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu1'; ClusterIp = '192.168.50.111' }
$cluster2 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu2'; ClusterIp = '192.168.50.121' }
Add-LabMachineDefinition -Name focln11 -Roles $cluster1
Add-LabMachineDefinition -Name focln12 -Roles $cluster1

Add-LabMachineDefinition -Name focln21 -Roles $cluster2
Add-LabMachineDefinition -Name focln22 -Roles $cluster2
```

## Storage  
In case you want your cluster to use a disk witness or generally experiment with storage in your clusters, you can select to deploy an iSCSI target with the new role FailoverStorage. A target will be created for each cluster, permitting only the cluster nodes to connect to it. During cluster setup, a disk witness will automatically be used for your cluster.  
```powershell
# Deploy iSCSI Target server with enough storage for your witness disks (1GB/cluster)
$storageRole = Get-LabMachineRoleDefinition -Role FailoverStorage -Properties @{LunDrive = 'D' }
Add-LabDiskDefinition -Name LunDisk -DiskSizeInGb 26
Add-LabMachineDefinition -Name foCLS1 -Roles $storageRole -DiskName LunDisk

# Deploy your cluster
$cluster1 = Get-LabMachineRoleDefinition -Role FailoverNode -Properties @{ ClusterName = 'Clu2'; ClusterIp = '192.168.50.111' }
Add-LabMachineDefinition -Name focln11 -Roles $cluster1
Add-LabMachineDefinition -Name focln12 -Roles $cluster1
Add-LabMachineDefinition -Name focln13 -Roles $cluster1
```