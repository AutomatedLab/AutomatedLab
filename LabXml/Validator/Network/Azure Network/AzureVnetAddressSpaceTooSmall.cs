using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab.Validator.Network.Azure_Network
{
    public class AzureVnetAddressSpaceTooSmall : LabValidator, IValidate
    {
        public AzureVnetAddressSpaceTooSmall()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var vnets = lab.VirtualNetworks.Where(adapter => adapter.HostType == VirtualizationHost.Azure && adapter.Subnets.Count > 0);
            if (vnets.Count() == 0)
                yield break;

            foreach (var vnet in vnets)
            {
                if (vnet.Subnets.Count > 1 && vnet.Subnets.Where(sn => sn.AddressSpace.Cidr >= vnet.AddressSpace.Cidr).Count() > 0 ||
                      vnet.Subnets.Count == 1 && vnet.Subnets.Where(sn => sn.AddressSpace.Cidr > vnet.AddressSpace.Cidr).Count() > 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = "At least one subnet's address space is bigger or equal to the virtual network's address space.",
                        HelpText = "Reexamine the CIDR of your Azure virtual network and the subnets you have configured. If you configure more than one subnet, make sure that the address space fits your subnets.",
                    };
                }
            }
        }
    }
}
