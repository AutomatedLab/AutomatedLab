using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator creates an error if a machine's name is longer than 15 characters.
    /// </summary>
    public class LabNameContainsIllegalCharacters : LabValidator, IValidate
    {
        public LabNameContainsIllegalCharacters()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var pattern = "^([A-Za-z0-9])+$";

            if (!System.Text.RegularExpressions.Regex.IsMatch(lab.Name, pattern))
            {
                yield return new ValidationMessage()
                {
                    Message = "The lab name contains invalid characters. Only A-Z, a-z and 0-9 are allowed.",
                    TargetObject = lab.Name,
                    Type = MessageType.Error,
                };
            }
        }
    }
}