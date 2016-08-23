using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// New external switch has a name collision with an already exisitng private or internal one.
    /// </summary>
    public class ExternalSwitchNameCollision : LabValidator, IValidate
    {
        public ExternalSwitchNameCollision()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var externalSwitches = lab.VirtualNetworks.Where(adapter => adapter.SwitchType == SwitchType.External);
            if (externalSwitches.Count() == 0)
                yield break;

            var existingExternalSwitches = LabXml.PowerShellHelper.InvokeCommand("Get-VMSwitch -SwitchType External | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name ConnectionName -Value (Get-NetAdapter -InterfaceDescription $_.NetAdapterInterfaceDescription).Name -PassThru }");
            var existingSwitches = LabXml.PowerShellHelper.InvokeCommand("Get-VMSwitch");

            var existingSwitchNames = existingSwitches.Where(sw => sw.Properties["SwitchType"].Value.ToString() == "Internal" | sw.Properties["SwitchType"].Value.ToString() == "Private").Select(sw => sw.Properties["Name"].Value.ToString());
            foreach (var sw in lab.VirtualNetworks.Where(sw => existingSwitchNames.Contains(sw.Name)))
            {
                yield return new ValidationMessage
                {
                    Message = "There is already a virtual switch with the same name but a different switch type",
                    TargetObject = sw.Name,
                    Type = MessageType.Warning
                };
            }
        }

    }
}
