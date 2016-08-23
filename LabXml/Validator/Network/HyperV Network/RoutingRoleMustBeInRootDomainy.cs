using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// The routing role must be in a root domain or non domain joined.
    /// </summary>
    public class RoutingRoleMustBeInRootDomainy : LabValidator, IValidate
    {
        public RoutingRoleMustBeInRootDomainy()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var routers = machines.Where(m => m.Roles.Select(r => r.Name).Contains(Roles.Routing) && m.IsDomainJoined).ToList();

            foreach (var router in routers.Where(m => !lab.IsRootDomain(m.DomainName)))
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("The routing role must be in a root domain or non domain joined. The router '{0}' is in domain '{1}'", router.Name, router.DomainName),
                    TargetObject = router.Name,
                    Type = MessageType.Error,
                    HelpText = "Put the router in one of the root domains."
                };
            }
        }

    }
}
