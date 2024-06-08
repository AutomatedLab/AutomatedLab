using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// If DCs are installed on Azure there must be a DNS server configured on the connected Virtual Network Site.
    /// </summary>
    public class AzureVnetDnsServerInvalid : LabValidator, IValidate
    {
        public AzureVnetDnsServerInvalid()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            //get all domain controllers
            var dcs = lab.Machines.Where(machine => machine.HostType == VirtualizationHost.Azure && (machine.Roles.Where(role => (role.Name & (Roles.RootDC | Roles.FirstChildDC | Roles.DC)) == role.Name).Count() == 1));

            //get all VNets with no DNS configured
            var vnetsWithDns = lab.VirtualNetworks.Where(vnet => vnet.HostType == VirtualizationHost.Azure && vnet.DnsServers.Count > 0);

            if (dcs.Count() == 0 | vnetsWithDns.Count() == 0)
                yield break;

            var dcIpAddresses = dcs.SelectMany(dc => dc.NetworkAdapters).SelectMany(na => na.Ipv4Address).Select(ip => ip.IpAddress).ToList();

            foreach (var vnet in vnetsWithDns)
            {
                foreach (var ip in vnet.DnsServers)
                {
                    if (!dcIpAddresses.Contains(ip))
                    yield return new ValidationMessage
                    {
                        Message = string.Format("The DNS server '{0}' configured on the VNet is probably not the right one. Make sure you point to a DNS server inside the lab.", ip),
                        TargetObject = vnet.Name,
                        Type = MessageType.Warning
                    };
                }
            }
        }
    }
}
