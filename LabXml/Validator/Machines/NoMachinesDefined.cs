using System.Collections.Generic;

namespace AutomatedLab
{
    /// <summary>
    /// This validator creates an error if no machine is defined in the lab.
    /// </summary>
    public class NoMachinesDefined : LabValidator, IValidate
    {
        public NoMachinesDefined()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            if (machines.Count == 0)
            {
                yield return new ValidationMessage()
                {
                    Message = "There are no machines defined in the lab",
                    TargetObject = lab.Name,
                    Type = MessageType.Error,
                };
            }
        }

    }
}