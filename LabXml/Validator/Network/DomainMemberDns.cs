using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// Validator checks if domain members point to a domain DNS inside the lab
    /// Domain Controllers point to themselves and to a second Domain Controller
    /// </summary>
    public class DomainMemberDns : LabValidator, IValidate
    {
        public DomainMemberDns()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var domainControllers = lab.Machines
                .Where(m => m.Roles.Select(r => r.Name).Where(r => (AutomatedLab.Roles.ADDS & r) == r).Count() > 0);

            foreach (var domainController in domainControllers)
            {
                var dcDns = domainController.NetworkAdapters
                .SelectMany(n => n.Ipv4DnsServers);

                if (!dcDns.First().AddressAsString.Equals(domainController.IpV4Address))
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("First DNS server {0} of domain controller {1} points to a different IP {2}", domainController.IpV4Address, domainController.Name, dcDns.First().AddressAsString),
                        TargetObject = domainController.IpV4Address,
                        Type = MessageType.Error
                    };
                }
            }

            foreach (var machine in lab.Machines.Where(m => !string.IsNullOrWhiteSpace(m.DomainName) && m.Roles.Select(r => r.Name).Where(r => (AutomatedLab.Roles.ADDS & r) == r).Count() == 0))
            {
                var domainDns = domainControllers.Where(dc => dc.DomainName.Equals(machine.DomainName)).Select(dc => dc.IpV4Address);
                var machineDns = machine.NetworkAdapters.SelectMany(n => n.Ipv4DnsServers).Where(dns => domainDns.Contains(dns.AddressAsString));

                if (machineDns.Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("DNS servers of {0} do not point to any of the domain controllers in it's domain", machine.Name),
                        TargetObject = machine.Name,
                        Type = MessageType.Error
                    };
                }
            }
        }
    }
}
