using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// This validator informs about all defined domains.
    /// </summary>
    public class DomainInformation : LabValidator, IValidate
    {
        public DomainInformation()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            foreach (var domain in lab.Domains)
            {
                yield return new ValidationMessage
                {
                    Message = "Domain defined",
                    Type = MessageType.Information,
                    TargetObject = domain.Name
                };
            }
        }
    }
}