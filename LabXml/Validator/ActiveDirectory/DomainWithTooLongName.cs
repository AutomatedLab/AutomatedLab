using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator creates an error if a machine's name is longer than 15 characters.
    /// </summary>
    public class DomainWithTooLongName : LabValidator, IValidate
    {
        public DomainWithTooLongName()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var domains = lab.Domains.Where(d => d.Name.Split('.')[0].Length > 15);

            foreach (var domain in domains)
            {
                yield return new ValidationMessage()
                {
                    Message = "The domain's name is longer than 15 characters",
                    TargetObject = domain.Name,
                    Type = MessageType.Error,
                };
            }
        }

    }
}