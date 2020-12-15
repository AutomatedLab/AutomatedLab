using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// New external switch has a name collision with an already exisitng private or internal one.
    /// </summary>
    public class DuplicateAddressAssigned : LabValidator, IValidate
    {
        public DuplicateAddressAssigned()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var dupliateAddresses = lab.Machines.SelectMany(m => m.NetworkAdapters)
                .SelectMany(n => n.Ipv4Address)
                .GroupBy(ip => ip.IpAddress)
                .Where(group => group.Count() > 1);

            if (dupliateAddresses.Count() == 0)
                yield break;

            foreach (var dupliateAddress in dupliateAddresses)
            {
                yield return new ValidationMessage
                {
                    Message = string.Format("The IP address {0} is assigned multiple times", dupliateAddress.Key),
                    TargetObject = dupliateAddress.ToList().Select(ip => ip.IpAddress.AddressAsString)
                        .Aggregate((a, b) => a + ", " + b),
                    Type = MessageType.Error
                };
            }
        }
    }
}