using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator creates an error if a machine's name is longer than 15 characters.
    /// </summary>
    public class MachineWithTooLongName : LabValidator, IValidate
    {
        public MachineWithTooLongName()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var machines = lab.Machines.Where(m => m.Name.Length > 15);

            foreach (var machine in machines)
            {
                yield return new ValidationMessage()
                {
                    Message = "The machine's name is longer than 15 characters",
                    TargetObject = machine.Name,
                    Type = MessageType.Error,
                };
            }
        }

    }
}