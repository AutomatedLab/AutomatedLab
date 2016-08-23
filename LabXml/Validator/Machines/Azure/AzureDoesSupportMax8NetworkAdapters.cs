using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator looks for Azure machine that have more than 4 network adapters and reports errors.
    /// </summary>
    public class AzureDoesSupportMax4NetworkAdapters : LabValidator, IValidate
    {
        public AzureDoesSupportMax4NetworkAdapters()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            foreach (var machine in machines.Where(m=>m.HostType == VirtualizationHost.Azure && m.NetworkAdapters.Count > 4))
            {
                yield return new ValidationMessage()
                {
                    Message = "Azure does not support machines with more than 8 network adapters",
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}