using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// DHCP is not supported on external switches.
    /// </summary>
    public class DuplicateAdapterAddressSpace : LabValidator, IValidate
    {
        public DuplicateAdapterAddressSpace()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var networks = lab.VirtualNetworks.Where(vn => vn.SwitchType != SwitchType.External).ToList();
            var vswitches = LabXml.PowerShellHelper.InvokeCommand(
                "Get-LabVirtualNetwork"
                );

            foreach (var vswitch in vswitches)
            {
                var overlappingAddress = networks.FirstOrDefault(nw => !nw.ResourceName.Equals(vswitch.Properties["ResourceName"].ToString()) && nw.AddressSpace.ToString().Equals(vswitch.Properties["AddressSpace"].ToString()));
                if (null != overlappingAddress)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("Duplicate address space. Existing adapter {0} has same address space ({1}) as {2}", vswitch.Properties["ResourceName"],overlappingAddress.AddressSpace, overlappingAddress.ResourceName),
                        TargetObject = "Internal or private switch",
                        Type = MessageType.Error,
                        HelpText = "Change the address space specified in Add-LabVirtualNetworkDefinition"
                    };
                }
            }
        }

    }
}
