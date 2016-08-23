using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator looks for Hyper-V machine that have more than 8 network adapters and reports errors.
    /// </summary>
    public class HypervDoesSupportMax8NetworkAdapters : LabValidator, IValidate
    {
        public HypervDoesSupportMax8NetworkAdapters()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            foreach (var machine in machines.Where(m=>m.HostType == VirtualizationHost.HyperV && m.NetworkAdapters.Count > 8))
            {
                yield return new ValidationMessage()
                {
                    Message = "Hyper-V does not support machines with more than 8 network adapters",
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}