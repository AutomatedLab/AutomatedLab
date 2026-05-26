using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab.Validator.FailoverCluster
{
    class DscSqlServerPresent : LabValidator, IValidate
    {
        public DscSqlServerPresent()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var role = Roles.DSCPullServer;
            var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0);
            var sqlServers = lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.SQLServer2016 || r.Name == Roles.SQLServer2017 || r.Name == Roles.SQLServer2019 || r.Name == Roles.SQLServer2022 || r.Name == Roles.SQLServer2025).Count() > 0);

            foreach (var machine in machines)
            {
                var dscRole = machine.Roles.Where(r => r.Name == role).FirstOrDefault();
                if (dscRole.Properties.ContainsKey("DatabaseEngine") && dscRole.Properties["DatabaseEngine"].ToLower() == "sql")
                {
                    if (dscRole.Properties.ContainsKey("SqlServer"))
                    {
                        var targetedSqlServer = dscRole.Properties["SqlServer"];
                        if (sqlServers.Where(m => m.Name == targetedSqlServer).Count() < 1)
                        {
                            yield return new ValidationMessage
                            {
                                Message = string.Format("The database server for the DSC Pull Server role is '{0}' but there is no supported SQL Server (2016, 2017, 2019, 2022 or 2025) defined in the lab with that name", targetedSqlServer),
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