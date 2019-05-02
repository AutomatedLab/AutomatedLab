using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// Roles take additional properties in a hashtable. If a propery is specified but no value assigned, somthing is wrong an need to be reported.
    /// </summary>
    public class HyperVWrongOs : LabValidator, IValidate
    {
        public HyperVWrongOs()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.HyperV).Count() > 0 && m.OperatingSystem.Version < new Version(10, 0));
            
            foreach (var machine in machines)
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("OS version {0} of VM {1} is too low to enable nested virtualization.", machine.OperatingSystem.Version.ToString(), machine.Name),
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}