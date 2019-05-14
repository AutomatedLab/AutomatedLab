using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;

namespace AutomatedLab
{
    /// <summary>
    /// Roles take additional properties in a hashtable. If a propery is specified but no value assigned, somthing is wrong an need to be reported.
    /// </summary>
    public class MandatoryRoleProperties : LabValidator, IValidate
    {
        public MandatoryRoleProperties()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            Hashtable mandatoryRoleProperties = (Hashtable)validationSettings["MandatoryRoleProperties"];
            var machinesWithRoles = machines.Where(machine => machine.Roles.Count > 0);

            foreach (var machine in machinesWithRoles)
            {
                foreach (var role in machine.Roles.Where(r => mandatoryRoleProperties.ContainsKey(r.Name.ToString())))
                {
                    var mandatoryKeys = new List<string>();
                    //var keysFromModule = mandatoryRoleProperties[role.Name.ToString()];
                    var keysFromModule = ((object[])((PSObject)mandatoryRoleProperties[role.Name.ToString()]).BaseObject).Cast<string>().ToArray();


                    if (keysFromModule.GetType().IsArray)
                        mandatoryKeys.AddRange(keysFromModule);
                    else
                        mandatoryKeys.Add(keysFromModule.FirstOrDefault());


                    foreach (string mandatoryRoleProperty in mandatoryKeys)
                    {
                        if (!role.Properties.ContainsKey(mandatoryRoleProperty) || string.IsNullOrEmpty(role.Properties[mandatoryRoleProperty]))
                        {
                            yield return new ValidationMessage
                            {
                                Message = string.Format("The property '{0}' is required for role '{1}'", mandatoryRoleProperty, role.Name),
                                Type = MessageType.Error,
                                TargetObject = machine.Name
                            };
                        }
                    }
                }
            }

        }
    }
}
