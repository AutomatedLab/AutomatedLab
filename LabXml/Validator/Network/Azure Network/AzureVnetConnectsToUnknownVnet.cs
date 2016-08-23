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
    public class AzureVnetConnectsToUnknownVnet : LabValidator, IValidate
    {
        public AzureVnetConnectsToUnknownVnet()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var vnets = lab.VirtualNetworks.Where(adapter => adapter.HostType == VirtualizationHost.Azure && adapter.ConnectToVnets.Count > 0);
            if (vnets.Count() == 0)
                yield break;


            foreach (var vnet in vnets)
            {
                var unknownVnets = vnet.ConnectToVnets.Except(vnets.Select(v => v.Name).ToList());
                if (unknownVnets.Count() > 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = string.Format("The Azure VNet {0} connects to VNet(s) that is / are unknown: {1}", vnet.Name, string.Join(", ", unknownVnets)),
                        TargetObject = vnet.Name,                        
                        Type = MessageType.Error
                    };
                }
            }
        }
    }
}