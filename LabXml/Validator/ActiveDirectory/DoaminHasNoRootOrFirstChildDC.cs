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
    public class DoaminHasNoRootOrFirstChildDC : LabValidator, IValidate
    {
        public DoaminHasNoRootOrFirstChildDC()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            foreach (var domain in lab.Domains)
            {
                var machinesInDomain = lab.Machines
                    .Where(m => !string.IsNullOrEmpty(m.DomainName))
                    .Where(machine => machine.DomainName.ToLower() == domain.Name.ToLower());
                var dcs = machinesInDomain.Where(machine => machine.Roles.Where(role =>
                role.Name == Roles.RootDC ||
                role.Name == Roles.FirstChildDC).Count() > 0);

                if (dcs.Count() < 1)
                {
                    yield return new ValidationMessage
                    {
                        Message = "Domain does not have a RootDC or FirstChildDC. Make sure that all domain contain this role and all machines are in the correct domains.",
                        Type = MessageType.Error,
                        TargetObject = domain.Name
                    };
                }

            }
        }
    }
}