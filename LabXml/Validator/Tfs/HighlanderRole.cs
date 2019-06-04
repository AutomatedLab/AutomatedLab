using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// There can only be one Azure DevOps role!
    /// Unless the machine is an actual machine that uses Azure DevOps Server
    /// </summary>
    public class HighlanderRole : LabValidator, IValidate
    {
        public HighlanderRole()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var devopsRole = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).First(r => r.ToString() == "AzDevOps");
            var machines = lab.Machines.Where(m => m.Roles.Count > 1 && m.Roles.Where(r => r.Name == devopsRole).Count() > 0 && m.SkipDeployment);

            foreach (var machine in machines)
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("Machine {0} is using Azure DevOps (dev.azure.com) but has other roles assigned.", machine.ToString()),
                    Type = MessageType.Error,
                    TargetObject = machine.ToString()
                };
            }
        }
    }
}