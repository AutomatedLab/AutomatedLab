using System;
using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator makes sure the required SQL Versions are present
    /// SCVMM 2019: SQL 2016, SQL 2017 (not SQL 2019)
    /// SCVMM 2016: SQL 2012, SQL 2014, SQL 2016
    /// </summary>
    public class ScvmmCorrectSql : LabValidator, IValidate
    {
        public ScvmmCorrectSql()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var scvmmRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().StartsWith("Scvmm"));
            var sqlRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().StartsWith("SQLServer"));
            var sqlvms = new List<Machine>();
            foreach (var role in sqlRoles)
            {
                lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0).ForEach(m => sqlvms.Add(m));
            }

            foreach (var role in scvmmRoles)
            {
                var scvmmvms = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0);
                foreach (var vm in scvmmvms.Where(m => ! m.Roles.FirstOrDefault(r => r.Name == role).Properties.ContainsKey("SkipServer")))
                {
                    if (vm.Roles.FirstOrDefault(r => r.Name == Roles.Scvmm2016) != null && sqlvms.Where(m => m.Roles.FirstOrDefault(r => r.Name == Roles.SQLServer2012 || r.Name == Roles.SQLServer2014 || r.Name == Roles.SQLServer2016) != null).Count() == 0)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("SCVMM Server 2016 requires SQL 2012, 2014 or 2016", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }

                    if (vm.Roles.FirstOrDefault(r => r.Name == Roles.Scvmm2019) != null && sqlvms.Where(m => m.Roles.FirstOrDefault(r => r.Name == Roles.SQLServer2016 || r.Name == Roles.SQLServer2017) != null).Count() == 0)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("SCVMM Server 2019 requires SQL 2016 or 2017", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }
                }
            }
        }
    }
}