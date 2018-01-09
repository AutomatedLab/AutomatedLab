using System.Collections.Generic;

namespace AutomatedLab.Azure
{
    public class AzureVirtualMachine : CopiedObject<AzureVirtualMachine>
    {
        public string AvailabilitySetName { get; set; }
        public string DeploymentName { get; set; }
        public string DNSName { get; set; }
        //Microsoft.WindowsAzure.Commands.ServiceManagement.Model.GuestAgentStatus GuestAgentStatus {get;set;}                                                       
        public string HostName { get; set; }
        public string InstanceErrorCode { get; set; }
        public string InstanceFaultDomain { get; set; }
        public string InstanceName { get; set; }
        public string InstanceSize { get; set; }
        public string InstanceStateDetails { get; set; }
        public string InstanceStatus { get; set; }
        public string InstanceUpgradeDomain { get; set; }
        public string IpAddress { get; set; }
        public string Label { get; set; }
        public string Name { get; set; }
        //Microsoft.WindowsAzure.Commands.ServiceManagement.Model.NetworkInterfaceList NetworkInterfaces {get;set;}                                                  
        public string OperationDescription { get; set; }
        public string OperationId { get; set; }
        public string OperationStatus { get; set; }
        public string PowerState { get; set; }
        public string PublicIPAddress { get; set; }
        public string PublicIPDomainNameLabel { get; set; }
        public List<string> PublicIPFqdns { get; set; }
        public string PublicIPName { get; set; }
        //System.Collections.Generic.List[Microsoft.WindowsAzure.Commands.ServiceManagement.Model.ResourceExtensionStatus] ResourceExtensionStatusList {get;set;}    
        public string ResourceGroupName { get; set; }
        public string Status { get; set; }
        public string VirtualNetworkName { get; set; }
        //Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVM VM {get;set;}                                                                         

        public AzureVirtualMachine()
        { }

        public override string ToString()
        {
            return Name;
        }
    }
}
