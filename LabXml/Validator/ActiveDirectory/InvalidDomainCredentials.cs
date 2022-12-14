using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// The local admin's passwords must match the domain admin's credentials on a machine promoted to a RootDC of FirstChildDC
    /// </summary>
    public class InvalidDomainCredentials : LabValidator, IValidate
    {
        public InvalidDomainCredentials()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var rootDcs = machines.Where(machine => machine.Roles.Select(role => role.Name).Contains(Roles.RootDC) && ! machine.SkipDeployment);
            var firstChildDcs = machines.Where(machine => machine.Roles.Select(role => role.Name).Contains(Roles.FirstChildDC) && ! machine.SkipDeployment);

            foreach (var dc in rootDcs)
            {
                var domain = lab.Domains.Where(d => d.Name.ToLower() == dc.DomainName.ToLower()).FirstOrDefault();

                if (dc.InstallationUser.Password != domain.Administrator.Password)
                {
                    yield return new ValidationMessage
                    {
                        Message = "The domain's admin user's password must be the same like the RootDCs installation user's password",
                        Type = MessageType.Error,
                        TargetObject = dc.Name
                    };
                }
            }

            foreach (var dc in firstChildDcs)
            {
                var domain = lab.Domains.Where(d => d.Name.ToLower() == dc.DomainName.ToLower()).FirstOrDefault();

                if (dc.InstallationUser.Password != domain.Administrator.Password)
                {
                    yield return new ValidationMessage
                    {
                        Message = "The domain's admin user's password must be the same like the FirstChildDcs installation user's password",
                        Type = MessageType.Error,
                        TargetObject = dc.Name
                    };
                }
            }
        }
    }
}