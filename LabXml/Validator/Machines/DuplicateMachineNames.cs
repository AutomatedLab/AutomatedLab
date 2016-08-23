using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator looks for duplicate machine names inside a lab.
    /// </summary>
    public class DuplicateMachineNames : LabValidator, IValidate
    {
        public DuplicateMachineNames()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var duplicateMachineGroups = machines.GroupBy(machine => machine.Name)
                .Where(group => group.Count() > 1);

            foreach (var duplicateMachineGroup in duplicateMachineGroups)
            {
                yield return new ValidationMessage()
                {
                    Message = "Duplicate Computer name defined",
                    Type = MessageType.Error,
                    TargetObject = duplicateMachineGroup.Key
                };
            }
        }
    }
}