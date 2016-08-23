using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// Roles take additional properties in a hashtable. If a propery is specified but no value assigned, somthing is wrong an need to be reported.
    /// </summary>
    public class EmptyRoleProperties : LabValidator, IValidate
    {
        public EmptyRoleProperties()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machinesWithRoles = machines.Where(machine => machine.Roles.Count > 0);

            foreach (var machine in machinesWithRoles)
            {
                foreach (var role in machine.Roles)
                {
                    var properties = role.Properties.Where(p => string.IsNullOrEmpty(p.Value));
                    foreach (var property in properties)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("The property '{0}' defined in role '{1}' is empty", property, role.Name),
                            Type = MessageType.Error,
                            TargetObject = machine.Name
                        };
                    }
                }
            }

        }
    }
}