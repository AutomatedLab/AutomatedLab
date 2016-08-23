using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// This validator informs about all roles defined in the lab.
    /// </summary>
    public class MachineRoleInformation : LabValidator, IValidate
    {
        public MachineRoleInformation()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            foreach (Roles role in Enum.GetValues(typeof(AutomatedLab.Roles)))
            {
                var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0);

                foreach (var machine in machines)
                {
                    yield return new ValidationMessage()
                    {
                        Message = "Role defined",
                        TargetObject = role.ToString(),
                        ValueName = machine.Name,
                        Type = MessageType.Information
                    };
                }
            }
        }

    }
}
