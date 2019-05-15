using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// This validator makes sure the required ISOs are present
    /// Azure DevOps Server 2019	Azure SQL Database, SQL Server 2017,  SQL Server 2016 (minimum SP1)
    /// TFS 2018	SQL Server 2017
    /// SQL Server 2016 (minimum SP1)
    /// TFS 2017 Update 1	SQL Server 2016 (minimum SP1)
    /// SQL Server 2014
    /// TFS 2017	SQL Server 2016
    /// SQL Server 2014
    /// TFS 2015 Update 3	SQL Server 2016
    /// SQL Server 2014
    /// SQL Server 2012 (minimum SP1)
    /// TFS 2015	SQL Server 2014
    /// SQL Server 2012 (minimum SP1)
    /// </summary>
    public class TfsSqlIsosExist : LabValidator, IValidate
    {
        public TfsSqlIsosExist()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var devopsRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => Regex.IsMatch(r.ToString(), @"Tfs\d{4}|AzDevOps"));

            foreach (var role in devopsRoles)
            {
                var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0 && !m.SkipDeployment);
                if (machines.Count() == 0) continue;

                List<string> sqlmachines = new List<string>();
                List<string> requiredRoles = new List<string>();
                switch (role)
                {
                    case Roles.Tfs2015:
                        requiredRoles.Add("2014");
                        sqlmachines.AddRange(lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.SQLServer2014).Count() > 0).Select(m => m.Name));
                        break;
                    case Roles.Tfs2017:
                        requiredRoles.Add("2014");
                        requiredRoles.Add("2016");
                        sqlmachines.AddRange(lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.SQLServer2014 || r.Name == Roles.SQLServer2016).Count() > 0).Select(m => m.Name));
                        break;
                    case Roles.Tfs2018:
                        requiredRoles.Add("2017");
                        sqlmachines.AddRange(lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.SQLServer2017).Count() > 0).Select(m => m.Name));
                        break;
                    case Roles.AzDevOps:
                        requiredRoles.Add("2017");
                        sqlmachines.AddRange(lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.SQLServer2017).Count() > 0).Select(m => m.Name));
                        break;
                    default:
                        break;
                }
                
                if (sqlmachines.Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("There is no fitting SQL server for TFS/DevOps server role '{0}' defined. {0} requires SQL roles {1}", role.ToString(), string.Join(",", requiredRoles.ToArray())),
                        Type = MessageType.Error,
                        TargetObject = role.ToString()
                    };
                }
            }
        }
    }
}