using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace AutomatedLab
{
    /// <summary>
    /// This validator makes sure the required SQL Versions are present
    /// Scom 2022: SQL 2017, SQL 2019, SQL 2022
    /// Scom 2019: SQL 2016, SQL 2017, SQL 2019
    /// Scom 2016: SQL 2012, SQL 2014, SQL 2016
    /// </summary>
    public class ScomCorrectSql : LabValidator, IValidate
    {
        public ScomCorrectSql()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var scomRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().Equals("ScomManagement") || r.ToString().Equals("ScomReporting"));
            var iso = lab.Sources.ISOs.First(isoSource => isoSource.Name.StartsWith("Scom"));
            var sqlRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().StartsWith("SQLServer"));
            var sqlvms = new List<Machine>();
            foreach (var role in sqlRoles)
            {
                lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0).ForEach(m => sqlvms.Add(m));
            }

            foreach (var role in scomRoles)
            {
                var scomvms = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0);
                foreach (var vm in scomvms.Where(m => ! m.Roles.FirstOrDefault(r => r.Name == role).Properties.ContainsKey("SkipServer")))
                {
                    if (Regex.IsMatch(System.IO.Path.GetFileNameWithoutExtension(iso.Path), "_2016_") && sqlvms.Where(m => m.Roles.FirstOrDefault(r => r.Name == Roles.SQLServer2012 || r.Name == Roles.SQLServer2014 || r.Name == Roles.SQLServer2016) != null).Count() == 0)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("Scom 2016 requires SQL 2012, 2014 or 2016", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }
                    if (Regex.IsMatch(System.IO.Path.GetFileNameWithoutExtension(iso.Path), "_2019_") && sqlvms.Where(m => m.Roles.FirstOrDefault(r => r.Name == Roles.SQLServer2016 || r.Name == Roles.SQLServer2017 || r.Name == Roles.SQLServer2019) != null).Count() == 0)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("Scom 2016 requires SQL 2016, 2017 or 2019", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }
                    if (Regex.IsMatch(System.IO.Path.GetFileNameWithoutExtension(iso.Path), "_2022_") && sqlvms.Where(m => m.Roles.FirstOrDefault(r => r.Name == Roles.SQLServer2017 || r.Name == Roles.SQLServer2019 || r.Name == Roles.SQLServer2022) != null).Count() == 0)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("Scom 2022 requires SQL 2017, 2019 or 2022", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }

                    if (!Regex.IsMatch(System.IO.Path.GetFileNameWithoutExtension(iso.Path), "_2016_|_2019_|_2022_") && sqlvms.Where(m => m.Roles.FirstOrDefault(r => r.Name == Roles.SQLServer2012 || r.Name == Roles.SQLServer2014 || r.Name == Roles.SQLServer2016 || r.Name == Roles.SQLServer2016 || r.Name == Roles.SQLServer2017 || r.Name == Roles.SQLServer2022) != null).Count() == 0)
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("Unknown Scom Version, ensure that your SQL version is actually supported.", vm.ToString()),
                            Type = MessageType.Warning,
                            TargetObject = vm.ToString()
                        };
                    }
                }
            }
        }
    }
}