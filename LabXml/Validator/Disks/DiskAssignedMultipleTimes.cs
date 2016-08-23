using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// Report all disks that are assigned more than once.
    /// </summary>
    public class DiskAssignedMultipleTimes : LabValidator, IValidate
    {
        public DiskAssignedMultipleTimes()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machineGroups = lab.Machines.SelectMany(m => m.Disks)
                .GroupBy(d => d.Name)
                .Where(g => g.Count() > 1);

            foreach (var machineGroup in machineGroups)
            {
                yield return new ValidationMessage
                {
                    Message = "Disk as assigned to two machines",
                    TargetObject = machineGroup.Key,
                    Type = MessageType.Error

                };
            }
        }
    }
}