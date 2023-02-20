using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    /// <summary>
    /// This validator looks for duplicate machine names inside a lab.
    /// </summary>
    public class HyperVAdminHasMachineName : LabValidator, IValidate
    {
        public HyperVAdminHasMachineName()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var adminUserNotPossible = machines.Where(mach => mach.HostType.Equals(VirtualizationHost.HyperV) && mach.InstallationUser.UserName.Equals(mach.Name, System.StringComparison.InvariantCultureIgnoreCase));

            foreach (var impossibleUser in adminUserNotPossible)
            {
                yield return new ValidationMessage()
                {
                    Message = $"Admin user name {impossibleUser.InstallationUser.UserName} may not be machine name {impossibleUser.Name}",
                    Type = MessageType.Error,
                    TargetObject = impossibleUser.Name
                };
            }
        }
    }
}