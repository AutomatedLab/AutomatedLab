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
    public class RoutingRoleNotSupportedOnAzure : LabValidator, IValidate
    {
        public RoutingRoleNotSupportedOnAzure()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var role = Roles.Routing;
            var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0 & m.HostType == VirtualizationHost.Azure);

            foreach (var machine in machines)
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("The role '{0}' is not supported on Azure", role.ToString()),
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}