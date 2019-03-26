using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace AutomatedLab
{
    /// <summary>
    /// Roles take additional properties in a hashtable. If a propery is specified but no value assigned, somthing is wrong an need to be reported.
    /// </summary>
    public class HyperVWrongRoleSize : LabValidator, IValidate
    {
        public HyperVWrongRoleSize()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.HyperV).Count() > 0 && m.HostType == VirtualizationHost.Azure);

            // According to https://docs.microsoft.com/en-us/azure/virtual-machines/windows/acu
            var validRoleSizePattern = @"_[DE]\d+(s?)_v3|_F\d+s_v2|_M\d+[mlts]*";

            foreach (var machine in machines)
            {
                var problematicRoleSize = string.Empty;

                if (!Regex.IsMatch(lab.AzureSettings.DefaultRoleSize, validRoleSizePattern))
                {
                    problematicRoleSize = lab.AzureSettings.DefaultRoleSize;
                }

                if (machine.AzureProperties.ContainsKey("RoleSize"))
                {
                    problematicRoleSize = string.Empty;

                    if (!Regex.IsMatch(machine.AzureProperties["RoleSize"], validRoleSizePattern))
                    {
                        problematicRoleSize = machine.AzureProperties["RoleSize"];
                    }
                }

                if (problematicRoleSize.Equals(string.Empty)) continue;

                var msg = "The role size '{0}' defined for machine '{1}' or the entire lab is too small for nested virtualization.\r\n" +
                    "Choose any role size that matches {2} as outlined on https://docs.microsoft.com/en-us/azure/virtual-machines/windows/acu";

                yield return new ValidationMessage
                {
                    Message = string.Format(msg, problematicRoleSize, machine.Name, validRoleSizePattern),
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}