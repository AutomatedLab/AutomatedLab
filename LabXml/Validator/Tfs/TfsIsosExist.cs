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
    /// </summary>
    public class TfsIsosExist : LabValidator, IValidate
    {
        public TfsIsosExist()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var devopsRoles = ((Roles[])Enum.GetValues(typeof(AutomatedLab.Roles))).Where(r => Regex.IsMatch(r.ToString(), @"Tfs\d{4}|AzDevOps"));

            foreach (var role in devopsRoles)
            {
                // SkipDeployment: It is an Azure DevOps hosted instance somewhere
                var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0 && !m.SkipDeployment);

                if (machines.Count() > 0 && lab.Sources.ISOs.Where(iso => iso.Name == role.ToString()).Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("There is no ISO image for '{0}' defined", role.ToString()),
                        Type = MessageType.Error,
                        TargetObject = role.ToString()
                    };
                }
            }
        }
    }
}