# Changelog

## v4.7.* - yyyy-mm-dd

### Fixes
- AL now creates all SQL service accounts
- New image names for server 1709 taken into account
- Random spelling and formatting
- Sync-Parameter fixed so that it works with PSv2 as well

### Enhancements
- Build and release process automated
- New sample scripts
- New module AutomatedLab.Common added as submodule
- SQL 2017 added
- SSMS installation streamlined
- SQL Server now customizable on Azure as well
- FQDN in host file

## v4.5.0.0 - 2017-11-18

### Fixes
- Sync-Parameter now syncs CmdletInfo objects as well
- Automatic Checkpoints (Win10 1709) disabled
- Mount-LabIsoImage on Hyper-V (Win10 1709) fixed
- Send-ModuleToPSSession now matches three and four digit versions
- Discoverabilty of Send-ALNotification improved (which fixed issues during module import)

### Enhancements
- Failover Clustering added
  - FailoverNode: Node of a failover cluster. Role properties: ClusterName and ClusterIp
  - FailoverStorage: iSCSI target server providing iSCSI targets for each cluster. If storage is deployed, the cluster will try to automatically use a disk witness
  - Install-LabFailoverCluster: Creates the failover cluster from all machines that are FailoverNode or FailoverStorage
  - Multidomain or Workgroup clusters with OS < Server 2016: Prior to 2016 it was not possible to deploy multidomain or workgroup clusters.
  - OS < 2008 R2: Cluster cmdlets work with 2008 R2 and above
  - Duplicate cluster IPs
  - Fewer than 2 nodes per cluster
  - Sample script that deploys three clusters with varying configurations  
- SQL Sample Database Installation revised
  - Sample DBs will now be downloaded
  - Customization of download links in AutomatedLab.psd1
- SQL Setup now auto-creates domain/local accounts
  - If username and password for the SQL accounts are specified in the role properties, AL takes care of creating them
