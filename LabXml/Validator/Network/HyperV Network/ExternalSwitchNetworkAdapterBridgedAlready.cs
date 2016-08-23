using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// check if the new external switch should be bound to a network adapter that is bridged already.
    /// </summary>
    public class ExternalSwitchNetworkAdapterBridgedAlready : LabValidator, IValidate
    {
        public ExternalSwitchNetworkAdapterBridgedAlready()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var newExternalSwitches = lab.VirtualNetworks.Where(sw => sw.SwitchType == SwitchType.External);
            if (newExternalSwitches.Count() == 0)
                yield break;

            var existingExternalSwitches = LabXml.PowerShellHelper.InvokeCommand(
                "Get-VMSwitch -SwitchType External | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name ConnectionName -Value (Get-NetAdapter -InterfaceDescription $_.NetAdapterInterfaceDescription).Name -PassThru }"
                );

            foreach (var existingExternalSwitch in existingExternalSwitches)
            {
                if (newExternalSwitches.Select(sw => sw.AdapterName).Contains(existingExternalSwitch.Properties["ConnectionName"].Value))
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("The network connection '{0}' is already bridged to virtual switch '{1}'", existingExternalSwitch.Properties["ConnectionName"].Value, existingExternalSwitch.Properties["Name"].Value),
                        TargetObject = existingExternalSwitch.Properties["ConnectionName"].Value.ToString(),
                        Type = MessageType.Warning
                    };
                }
            }
        }

    }
}
