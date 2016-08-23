using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// DHCP is not supported on external switches.
    /// </summary>
    public class ExternalSwitchNoDhcp : LabValidator, IValidate
    {
        public ExternalSwitchNoDhcp()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var dhcpServers = machines.Where(m => m.Roles.Select(r => r.Name).Contains(Roles.DHCP)).ToList();
            var externalSwitches = lab.VirtualNetworks.Where(adapter => adapter.SwitchType == SwitchType.External);

            if (externalSwitches.Count() > 0 && dhcpServers.Count() > 0)
            {
                yield return new ValidationMessage
                {
                    Message = "DHCP servers are not supported when using external virtual switches",
                    TargetObject = "External Network Switch",
                    Type = MessageType.Error,
                    HelpText = "Remove the DHCP server which is connected to the external switch."
                };
            }
        }

    }
}
