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
    public class ScvmmMinOsVersion : LabValidator, IValidate
    {
        public ScvmmMinOsVersion()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var scvmmRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => r.ToString().StartsWith("Scvmm"));


            foreach (var role in scvmmRoles)
            {
                var scvmmServers = new List<Machine>();
                var scvmmConsoles = new List<Machine>();
                lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0 && !m.Roles.FirstOrDefault(r => r.Name == role).Properties.ContainsKey("SkipServer")).ForEach(m => scvmmServers.Add(m));
                lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0 && m.Roles.FirstOrDefault(r => r.Name == role).Properties.ContainsKey("SkipServer")).ForEach(m => scvmmConsoles.Add(m));

                foreach (var vm in scvmmServers)
                {
                    if (vm.Roles.FirstOrDefault(r => r.Name == Roles.Scvmm2016 || r.Name == Roles.Scvmm2019) != null && vm.OperatingSystem.Version < new Version(10, 0))
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("SCVMM 2016/2019 requires at least Windows Server 2016", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }
                }
                foreach (var vm in scvmmConsoles)
                {
                    if (vm.Roles.FirstOrDefault(r => r.Name == Roles.Scvmm2016) != null && vm.OperatingSystem.Version < new Version(6, 2))
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("SCVMM 2016 Console requires at least Windows Server 2012", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }

                    if (vm.Roles.FirstOrDefault(r => r.Name == Roles.Scvmm2019) != null && vm.OperatingSystem.Version < new Version(10, 0))
                    {
                        yield return new ValidationMessage
                        {
                            Message = string.Format("SCVMM 2019 Console requires Windows Server 2016 or 2019", vm.ToString()),
                            Type = MessageType.Error,
                            TargetObject = vm.ToString()
                        };
                    }
                }
            }
        }
    }
}