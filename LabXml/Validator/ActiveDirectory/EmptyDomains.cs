using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// Reports all defined domains which do not have any member machine
    /// </summary>
    public class EmptyDomains : LabValidator, IValidate
    {
        public EmptyDomains()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var emptyDomains = lab.Domains
        .Select(domain => domain.Name.ToLower())
        .Except(machines.Where(m => !string.IsNullOrEmpty(m.DomainName)).Select(machine => machine.DomainName.ToLower()));

            foreach (var emptyDomain in emptyDomains)
            {
                yield return new ValidationMessage
                {
                    Message = "Defined domain does not have any member machines",
                    Type = MessageType.Warning,
                    TargetObject = emptyDomain
                };
            }
        }
    }
}