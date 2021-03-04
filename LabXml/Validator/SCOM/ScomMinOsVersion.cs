using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace AutomatedLab
{
    /// <summary>
    /// This validator makes sure the required OS Versions are used
    /// </summary>
    public class ScomMinOsVersion : LabValidator, IValidate
    {
        public ScomMinOsVersion()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.ScomConsole || r.Name == Roles.ScomManagement || r.Name == Roles.ScomReporting || r.Name == Roles.ScomWebConsole).Count() > 0 && m.OperatingSystem.Version < new Version(10, 0));

            foreach (var machine in machines)
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("OS version {0} too low, required >=10.0", machine.OperatingSystem.Version.ToString()),
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}