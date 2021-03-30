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
    public class ScomIsosExist : LabValidator, IValidate
    {
        public ScomIsosExist()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var scomRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().StartsWith("Scom"));

            foreach (var role in scomRoles)
            {
                var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0 & m.HostType == VirtualizationHost.HyperV);

                if (machines.Count() > 0 & lab.Sources.ISOs.Where(iso => iso.Name == "ScomManagement").Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("There is no ISO image for 'ScomManagement' defined. Regardless of the SCOM component, please add the ISO with the name ScomManagement"),
                        Type = MessageType.Error,
                        TargetObject = role.ToString()
                    };
                }
            }
        }
    }
}