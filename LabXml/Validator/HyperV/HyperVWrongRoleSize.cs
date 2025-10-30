using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace AutomatedLab
{
    /// <summary>
    /// Roles take additional properties in a hashtable. If a propery is specified but no value assigned, somthing is wrong an need to be reported.
    /// </summary>
    public class HyperVWrongRoleSize : LabValidator, IValidate
    {
        public HyperVWrongRoleSize()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.HyperV).Count() > 0 && m.HostType == VirtualizationHost.Azure);

            /* According to https://docs.microsoft.com/en-us/azure/virtual-machines/windows/acu
             the following SKUs support nested virt as of October 2025
                Standard_D2as_v7
                Standard_D2ads_v7
                Standard_D2als_v7
                Standard_D2alds_v7
                Standard_D2s_v6
                Standard_D2ds_v6
                Standard_D2ls_v6
                Standard_D2lds_v6
                Standard_D2as_v6
                Standard_D2ads_v6
                Standard_D2als_v6
                Standard_D2alds_v6
                Standard_D2_v5
                Standard_D2s_v5
                Standard_D2d_v5
                Standard_D2ds_v5
                Standard_D2as_v5
                Standard_D2ads_v5
                Standard_D2ls_v5
                Standard_D2lds_v5
                Standard_D2ns_v6
                Standard_D2nds_v6
                Standard_D2nls_v6
                Standard_D2nlds_v6
                Standard_F1as_v7
                Standard_F1ads_v7
                Standard_F1ams_v7
                Standard_F1amds_v7
                Standard_F1als_v7
                Standard_F1alds_v7
                Standard_F2as_v6
                Standard_F2als_v6
                Standard_F2ams_v6
                Standard_F2s_v2
                Standard_FX2ms_v2
                Standard_FX2mds_v2
                Standard_FX4mds
                Standard_E2as_v7
                Standard_E2s_v4
                Standard_E2_v4
                Standard_E2ds_v4
                Standard_E2d_v4
                Standard_E2nds_v6
                Standard_E2ns_v6
                Standard_E2ads_v5
                Standard_E2as_v5
                Standard_E2ds_v5
                Standard_E2d_v5
                Standard_E2s_v5
                Standard_E2_v5
                Standard_E2ads_v6
                Standard_E2as_v6
                Standard_E2ds_v6
                Standard_E2s_v6
                Standard_E2ads_v7
                Standard_E2bds_v5
                Standard_L8as_v3
                Standard_L8s_v3
                Standard_L2s_v4
                Standard_L2as_v4
                Standard_L2aos_v4
            */
            var validRoleSizePattern = @"Standard_((D\d+a[ld]{0,2}s_v7)|(D\d+[an]?[ld]{0,2}s_v[56])|(F\d+a[mld]{0,2}s_v7)|(F\d+a[lm]s_v6)|(F\d+s_v2)|(FX\d+[md]{0,2}s_v2)|(E\d+as_v7)|(E\d+[nds]{0,3}_v4)|(E\d+nd?s_v6)|(E\d+[ads]{0,3}_v5)|(E\d+[ad]{0,3}s_v6)|(E\d+ads_v7)|(E\d+bds_v5)|(L\d+a?s_v3)|(L\d+[ao]{0,2}s_v4))";

            foreach (var machine in machines)
            {
                var problematicRoleSize = string.Empty;

                if (!Regex.IsMatch(lab.AzureSettings.DefaultRoleSize, validRoleSizePattern))
                {
                    problematicRoleSize = lab.AzureSettings.DefaultRoleSize;
                }

                if (machine.AzureProperties.ContainsKey("RoleSize"))
                {
                    problematicRoleSize = string.Empty;

                    if (!Regex.IsMatch(machine.AzureProperties["RoleSize"], validRoleSizePattern))
                    {
                        problematicRoleSize = machine.AzureProperties["RoleSize"];
                    }
                }

                if (problematicRoleSize.Equals(string.Empty)) continue;

                var msg = "The role size '{0}' defined for machine '{1}' or the entire lab is too small for nested virtualization.\r\n" +
                    "Choose any role size that matches {2} as outlined on https://docs.microsoft.com/en-us/azure/virtual-machines/windows/acu";

                yield return new ValidationMessage
                {
                    Message = string.Format(msg, problematicRoleSize, machine.Name, validRoleSizePattern),
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}