using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator looks for Hyper-V machine that have more than 8 network adapters and reports errors.
    /// </summary>
    public class HypervMemorySettings : LabValidator, IValidate
    {
        public HypervMemorySettings()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            foreach (var machine in machines.Where(m => m.HostType == VirtualizationHost.HyperV))
            {
                if (
                    (machine.MaxMemory != 0 & machine.MinMemory == 0) |
                    (machine.MaxMemory == 0 & machine.MinMemory != 0)
                )
                    yield return new ValidationMessage()
                    {
                        Message = "If MaxMemory is defined MinMemory has to be defined as well and vice versa.",
                        Type = MessageType.Error,
                        TargetObject = machine.Name
                    };

                if (machine.MinMemory != 0 && (machine.MinMemory > machine.Memory) | (machine.MinMemory > machine.MaxMemory))
                    yield return new ValidationMessage()
                    {
                        Message = "MinMemory is larger than MaxMemory or Memory",
                        Type = MessageType.Error,
                        TargetObject = machine.Name
                    };
            }
        }
    }
}