using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab.Validator.FailoverCluster
{
    class DscSqlServerKnown : LabValidator, IValidate
    {
        public DscSqlServerKnown()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var role = Roles.DSCPullServer;
            var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0);

            foreach (var machine in machines)
            {
                var dscRole = machine.Roles.Where(r => r.Name == role).FirstOrDefault();
                if (dscRole.Properties.ContainsKey("DatabaseEngine") && dscRole.Properties["DatabaseEngine"].ToLower() == "sql")
                {
                    if (!dscRole.Properties.ContainsKey("SqlServer"))
                    {
                        yield return new ValidationMessage
                        {
                            Message = "The database engine for the DSC Pull Server role is 'sql' but there is no 'SqlServer' defined",
                            Type = MessageType.Error,
                            TargetObject = machine.Name
                        };
                    }

                    if (!dscRole.Properties.ContainsKey("DatabaseName"))
                    {
                        yield return new ValidationMessage
                        {
                            Message = "The database engine for the DSC Pull Server role is 'sql' but there is no 'DatabaseName' defined",
                            Type = MessageType.Error,
                            TargetObject = machine.Name
                        };
                    }
                }
            }
        }
    }
}