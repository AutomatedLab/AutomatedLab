# System Center Virtual Machine Manager

AutomatedLab supports the deployment of clusters, hypervisors - and of course it
supports deployment of a VMM instance to try managing them all. In general, the role
SCVMM2016 and SCVMM2019 can use all parameters that you can normally supply during
server or console deployment.  

During a lab deployment, as long as you have the correct SQL Server Version on a
machine in your lab as well, the database configuration will be automatic. Credential
handling will of course be automatic as well.

Other than that, the VMM environment will not be configured, so that you can customize
your deployment via Invoke-LabCommand or a PostInstallationActivity later on!

AutomatedLab-specific:
- SkipServer: Use, if only console should be deployed. Useful to configure an on-premises server that this console connects to
- ConnectHyperVRoleVms: Use a comma-separated string to specify, which Hyper-V lab VMs should connect to VMM

VMM-specific, refer to official documentation or just leave the defaults:
- UserName
- CompanyName
- ProgramFiles
- CreateNewSqlDatabase
- RemoteDatabaseImpersonation
- SqlMachineName
- IndigoTcpPort
- IndigoHTTPSPort
- IndigoNETTCPPort
- IndigoHTTPPort
- WSManTcpPort
- BitsTcpPort
- CreateNewLibraryShare
- LibraryShareName
- LibrarySharePath
- LibraryShareDescription
- SQMOptIn
- MUOptIn
- VmmServiceLocalAccount