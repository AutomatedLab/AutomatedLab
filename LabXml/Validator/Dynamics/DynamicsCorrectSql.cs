using System;
using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator makes sure the required SQL Versions are present
    /// Dynamics 365: SQL 2016+
    /// </summary>
    public class DynamicsCorrectSql : LabValidator, IValidate
    {
        public DynamicsCorrectSql()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var DynamicsRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().StartsWith("Dynamics"));
            var sqlRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().StartsWith("SQLServer"));
            var sqlvms = new List<Machine>();
            foreach (var role in sqlRoles)
            {
                lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0).ForEach(m => sqlvms.Add(m));
            }

            foreach (var role in DynamicsRoles)
            {
                var Dynamicsvms = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0);
                foreach (var vm in Dynamicsvms)
                {
                    if (vm.Roles.FirstOrDefault(r => r.Name == Roles.DynamicsFull | r.Name == Roles.DynamicsAdmin | r.Name == Roles.DynamicsBackend | r.Name == Roles.DynamicsFrontend) != null && sqlvms.Where(m => m.Roles.FirstOrDefault(r => r.Name == Roles.SQLServer2016 || r.Name == Roles.SQLServer2017) != null).Count() == 0)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("Dynamics 365 on {0} requires SQL 2016 or newer", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }
                }
            }
        }
    }
}