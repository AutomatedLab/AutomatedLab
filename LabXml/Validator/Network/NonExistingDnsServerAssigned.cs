using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// New external switch has a name collision with an already exisitng private or internal one.
    /// </summary>
    public class NonExistingDnsServerAssigned : LabValidator, IValidate
    {
        public NonExistingDnsServerAssigned()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var dnsServers = lab.Machines
                .Where(m => m.Roles.Select(r => r.Name).Where(r => (AutomatedLab.Roles.ADDS & r) == r).Count() == 0)
                .SelectMany(m =>m.NetworkAdapters)
                .SelectMany(n => n.Ipv4DnsServers);

            var nonExistingDnssServers = lab.Machines
                .SelectMany(m => m.NetworkAdapters)
                .SelectMany(n => n.Ipv4DnsServers)
                .Where(dns => !dnsServers.Contains(dns));

            if (nonExistingDnssServers.Count() == 0)
                yield break;

            foreach (var nonExistingDnssServer in nonExistingDnssServers)
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("The DNS server client address {0} does not point to a valid DNS server in the lab", nonExistingDnssServer.AddressAsString),
                    TargetObject = nonExistingDnssServer.AddressAsString,
                    Type = MessageType.Error
                };
            }
        }
    }
}
