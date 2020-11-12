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
    public class ScvmmIsosExist : LabValidator, IValidate
    {
        public ScvmmIsosExist()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var sqlRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().StartsWith("Scvmm"));

            foreach (var role in sqlRoles)
            {
                var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0 & m.HostType == VirtualizationHost.HyperV);

                if (machines.Count() > 0 & lab.Sources.ISOs.Where(iso => iso.Name == role.ToString()).Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("There is no ISO image for '{0}' defined", role.ToString()),
                        Type = MessageType.Error,
                        TargetObject = role.ToString()
                    };
                }
            }
        }
    }
}