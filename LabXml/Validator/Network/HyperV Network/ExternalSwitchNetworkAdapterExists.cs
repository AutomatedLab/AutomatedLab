using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// Check if the specified network adapter for the external switches exists and generate an error if it does not.
    /// </summary>
    public class ExternalSwitchNetworkAdapterExists : LabValidator, IValidate
    {
        public ExternalSwitchNetworkAdapterExists()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var externalSwitches = lab.VirtualNetworks.Where(sw => sw.SwitchType == SwitchType.External);
            if (externalSwitches.Count() == 0)
                yield break;

            var networkAdapters = LabXml.PowerShellHelper.InvokeCommand("Get-NetAdapter");

            foreach (var networkSwitch in externalSwitches)
            {
                var networkAdapter = networkAdapters.Where(na => na.Properties["InterfaceType"].Value.ToString() == "6" && na.Properties["Name"].Value.ToString().ToLower() == networkSwitch.ResourceName.ToLower());
                if (networkAdapters.Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("The specified physical non-Wi-Fi adapter '{0}' does not exist", networkSwitch.AdapterName),
                        TargetObject = networkSwitch.ResourceName,
                        Type = MessageType.Error
                    };
                }
            }
        }

    }
}
