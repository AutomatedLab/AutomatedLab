using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// This validator check if there is only one RootDC / FirstChildDC per domain defined.
    /// </summary>
    public class DuplicateDomainRoles : LabValidator, IValidate
    {
        public DuplicateDomainRoles()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var rootDcs = machines.Where(machine => machine.Roles.Select(role => role.Name).Contains(Roles.RootDC));
            var firstChildDcs = machines.Where(machine => machine.Roles.Select(role => role.Name).Contains(Roles.FirstChildDC));

            //each domain is a group that is checked for more than one RootDc
            foreach (var group in rootDcs.GroupBy(machine => machine.DomainName))
            {
                if (group.Count() > 1)
                {
                    yield return new ValidationMessage
                    {
                        Message = "The role RootDC is assinged more than once for the domain",
                        TargetObject = group.Key,
                        Type = MessageType.Error
                    };
                }
            }

            //check if there are more than one FirstChildDC per domain
            var dcGroups = firstChildDcs
                .GroupBy(dc => dc.Roles.Where(role => role.Name == Roles.FirstChildDC & !role.Properties.ContainsKey("NewDomain")))
                .Where(group => group.Count() > 1);

            foreach (var dcGroup in dcGroups)
            {
                foreach (var dc in dcGroup)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("The role FirstChildDC is assinged more than once for child domain '{0}'", dc.Roles.Where(role => role.Name == Roles.FirstChildDC).FirstOrDefault().Properties["NewDomain"]),
                        TargetObject = dc.Name,
                        Type = MessageType.Error
                    };
                }
            }
        }
    }
}