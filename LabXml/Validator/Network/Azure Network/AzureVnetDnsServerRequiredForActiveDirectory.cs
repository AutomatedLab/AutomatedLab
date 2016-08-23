using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// If DCs are installed on Azure there must be a DNS server configured on the connected Virtual Network Site.
    /// </summary>
    public class AzureVnetDnsServerRequiredForActiveDirectory : LabValidator, IValidate
    {
        public AzureVnetDnsServerRequiredForActiveDirectory()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            //get all domain controllers
            var dcs = lab.Machines.Where(machine => machine.HostType == VirtualizationHost.Azure && (machine.Roles.Where(role => (role.Name & (Roles.RootDC | Roles.FirstChildDC | Roles.DC)) == role.Name).Count() == 1));

            //get all VNets with no DNS configured
            var vnetsWithNoDns = lab.VirtualNetworks.Where(vnet => vnet.HostType == VirtualizationHost.Azure && vnet.DnsServers.Count == 0);

            if (dcs.Count() == 0 | vnetsWithNoDns.Count() == 0)
                yield break;

            foreach (var vnet in vnetsWithNoDns)
            {
                yield return new ValidationMessage
                {
                    Message = "Active Directory is configured in the lab but no DNS server is assigned on the VNet",
                    TargetObject = vnet.Name,
                    Type = MessageType.Error
                };
            }
        }
    }
}