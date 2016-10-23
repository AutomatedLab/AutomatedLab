using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// Roles take additional properties in a hashtable. If a propery is specified but no value assigned, somthing is wrong an need to be reported.
    /// </summary>
    public class UnknownRoleProperties : LabValidator, IValidate
    {
        public UnknownRoleProperties()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var validRoleProperties = (Hashtable)validationSettings["ValidRoleProperties"];
            var machinesWithRoles = machines.Where(machine => machine.Roles.Count > 0);

            foreach (var machine in machinesWithRoles)
            {
                foreach (var role in machine.Roles.Where(r => validRoleProperties.ContainsKey(r.Name.ToString())))
                {
                    var unknownProperties = role.Properties.Keys.Where(p =>
                        ((object[])validRoleProperties[role.Name.ToString()])
                        .Cast<string>()
                        .Where(vp => vp == p).Count() == 0);

                    foreach (var unknownProperty in unknownProperties)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("The property '{0}' is unknwon for role '{1}'", unknownProperty, role.Name),
                            Type = MessageType.Error,
                            TargetObject = machine.Name
                        };
                    }
                }
            }

        }
    }
}