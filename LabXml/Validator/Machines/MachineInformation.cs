using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// This validator informs about all defined machines.
    /// </summary>
    public class MachineInformation : LabValidator, IValidate
    {
        public MachineInformation()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            foreach (var machine in machines)
            {
                yield return new ValidationMessage()
                {
                    Message = "Machine defined in lab",
                    TargetObject = machine.Name,
                    Type = MessageType.Information,
                };
            }
        }

    }
}
