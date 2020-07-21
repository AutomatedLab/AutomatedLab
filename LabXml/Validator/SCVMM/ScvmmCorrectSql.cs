using System;
using System.CodeDom;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

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
            List<Machine> sqlvms= new List<Machine>();
            foreach (var role in sqlRoles)
            {
                lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0 & m.HostType == VirtualizationHost.HyperV).ForEach(m => sqlvms.Add(m));
            }

            foreach (var role in scvmmRoles)
            {
                if (role == Roles.Scvmm2016 && sqlvms.Where(m => m.Roles.Where(r => r.Name == Roles.SQLServer2012 || r.Name == Roles.SQLServer2014 || r.Name == Roles.SQLServer2016).Count() >= 0).Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("SCVMM 2016 requires SQL 2012, 2014 or 2016", role.ToString()),
                        Type = MessageType.Error,
                        TargetObject = role.ToString()
                    };
                }

                if (role == Roles.Scvmm2019 && sqlvms.Where(m => m.Roles.Where(r => r.Name == Roles.SQLServer2016 || r.Name == Roles.SQLServer2017).Count() >= 0).Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("SCVMM 2016 requires SQL 2016 or 2017", role.ToString()),
                        Type = MessageType.Error,
                        TargetObject = role.ToString()
                    };
                }
            }
        }
    }
}