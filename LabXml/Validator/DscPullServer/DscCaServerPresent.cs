using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab.Validator.FailoverCluster
{
    class DscCaServerPresent : LabValidator, IValidate
    {
        public DscCaServerPresent()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var certificateAuthorities = lab.Machines.Where(m => m.Roles.Where(r => r.Name == Roles.CaRoot || r.Name == Roles.CaSubordinate).Count() > 0);
            var role = Roles.DSCPullServer;
            var machines = lab.Machines.Where(m => m.Roles.Where(r => r.Name == role).Count() > 0);

            foreach (var machine in machines)
            {
                if (certificateAuthorities.Count() == 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = "There are no Certificate Authorities present in the lab. Cannot deploy DSC Pull Server",
                        HelpText = "Use Add-LabMachineDefinition -Roles CARoot to deploy a new CA",
                        Type = MessageType.Error,
                        TargetObject = machine.Name
                    };
                }
            }
        }
    }
}