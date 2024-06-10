using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator looks for non-supported combos of OS and VM Generation.
    /// </summary>
    public class AzureVmGenerationDoesNotFitSku : LabValidator, IValidate
    {
        public AzureVmGenerationDoesNotFitSku()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            if (lab.AzureSettings == null)
                yield break;

            var azVms = machines.Where(machine => machine.HostType == VirtualizationHost.Azure);

            foreach (var machine in azVms)
            {
                var azImg = lab.AzureSettings.VmImages.Where(s => s.AutomatedLabOperatingSystemName == machine.OperatingSystem.OperatingSystemName && s.HyperVGeneration.ToLower() == $"v{machine.VmGeneration}");

                if (azImg != null) continue;

                yield return new ValidationMessage()
                {
                    Message = string.Format("VM {0} is of generation {1}, but no OS was found that matches {2} and generation {1}", machine.Name, machine.VmGeneration, machine.OperatingSystem.OperatingSystemName),
                    Type = MessageType.Error,
                    TargetObject = machine.Name
                };
            }
        }
    }
}