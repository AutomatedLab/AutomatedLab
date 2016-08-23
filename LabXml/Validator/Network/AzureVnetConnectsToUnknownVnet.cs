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
    public class DuplicateAddressSpaceAssigned : LabValidator, IValidate
    {
        public DuplicateAddressSpaceAssigned()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var dupliateAddressSpaces = lab.VirtualNetworks.GroupBy(adapter => adapter.AddressSpace).Where(group => group.Count() > 1);
            if (dupliateAddressSpaces.Count() == 0)
                yield break;

            foreach (var dupliateAddressSpace in dupliateAddressSpaces)
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("The address space {0} is assigned multiple times", dupliateAddressSpace.Key),
                    TargetObject = dupliateAddressSpace.ToList().Select(vnet => vnet.Name).Aggregate((a, b) => a + ", " + b),
                    Type = MessageType.Error
                };
            }
        }
    }
}