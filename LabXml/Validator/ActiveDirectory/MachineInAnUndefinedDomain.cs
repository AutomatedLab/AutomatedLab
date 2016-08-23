using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// Print one error for each machine that is in an undefined domain
    /// </summary>
    public class MachineInAnUndefinedDomain : LabValidator, IValidate
    {
        public MachineInAnUndefinedDomain()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machines = lab.Machines.Where(machine => !string.IsNullOrEmpty(machine.DomainName))
                .Where(machine => !lab.Domains.Select(domain => domain.Name.ToLower()).Contains(machine.DomainName.ToLower()));

            foreach (var machine in machines)
            {
                yield return new ValidationMessage
                {
                    Message = "Machine is in a undefined domain",
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}