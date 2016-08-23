using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// This validator makes sure the required ISOs are present
    /// </summary>
    public class RoutingMachineHasAtLeastTwoNetworkCards : LabValidator, IValidate
    {
        public RoutingMachineHasAtLeastTwoNetworkCards()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machines = lab.Machines.Where(m => m.Roles.Where(r =>
            r.Name == Roles.Routing).Count() > 0 &
            m.HostType == VirtualizationHost.HyperV
            & m.NetworkAdapters.Count < 2);

            foreach (var machine in machines)
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("The machine '{0}' does not have at least 2 network interfaces for routing", machine.Name),
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}