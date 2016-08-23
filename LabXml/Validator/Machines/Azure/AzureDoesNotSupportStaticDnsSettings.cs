using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator looks for duplicate machine names inside a lab.
    /// </summary>
    public class AzureDoesNotSupportStaticDnsSettings : LabValidator, IValidate
    {
        public AzureDoesNotSupportStaticDnsSettings()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var azureMachinesWithDnsSettings = machines
                .Where(machine => machine.HostType == VirtualizationHost.Azure)
                .Where(machine => machine.NetworkAdapters.Where(na => na.Ipv4DnsServers.Count > 0)
                .Count() > 0);

            foreach (var machine in azureMachinesWithDnsSettings)
            {
                yield return new ValidationMessage()
                {
                    Message = "Azure does not support static IPs and DNS settings. All machines in a network will get a DNS servers assinged from the Virtual Network. The specified DNS server will be ignored",
                    Type = MessageType.Warning,
                    TargetObject = machine.Name
                };
            }
        }
    }
}