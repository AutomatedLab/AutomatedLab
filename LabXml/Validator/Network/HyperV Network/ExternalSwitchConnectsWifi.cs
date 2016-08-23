using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// Check if the an external switch connects to a WiFi adapter. This is not supported.
    /// </summary>
    public class ExternalSwitchConnectsWifi : LabValidator, IValidate
    {
        public ExternalSwitchConnectsWifi()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var externalSwitches = lab.VirtualNetworks.Where(sw => sw.SwitchType == SwitchType.External);
            if (externalSwitches.Count() == 0)
                yield break;

            var networkAdapters = LabXml.PowerShellHelper.InvokeCommand("Get-NetAdapter");

            foreach (var networkSwitch in lab.VirtualNetworks.Where(sw => sw.SwitchType == SwitchType.External))
            {
                var networkAdapter = networkAdapters.Where(na => na.Properties["InterfaceType"].Value.ToString() == "71" && na.Properties["Name"].Value.ToString().ToLower() == networkSwitch.Name.ToLower());
                if (networkAdapter.Count() == 1)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("The specified physical adapter '{0}' is a Wi-Fi adapter which is not supprted", networkSwitch.AdapterName),
                        TargetObject = networkSwitch.Name,
                        Type = MessageType.Error,
                        HelpText = "Connect the external switch to a non-WiFi adapter"
                    };
                }
            }
        }
    }
}
