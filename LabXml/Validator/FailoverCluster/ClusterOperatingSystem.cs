using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab.Validator.FailoverCluster
{
    class ClusterOperatingSystem : LabValidator, IValidate
    {
        public ClusterOperatingSystem()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var failoverNodes = machines.Where(machine => machine.Roles.Select(role => role.Name).Contains(Roles.FailoverNode));

            if (null != failoverNodes)
            {
                var oldOs = failoverNodes.Where(machine => machine.OperatingSystem.Version < new Version { Major = 6, Minor = 1 });
                if (oldOs.Count() != 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = "Failover clustering only works with 2008 R2 or greater",
                        TargetObject = string.Join(", ", from item in oldOs select item.Name),
                        Type = MessageType.Error
                    };
                }
            }

            var storageNodes = machines.Where(machine => machine.Roles.Select(role => role.Name).Contains(Roles.FailoverStorage));

            if (null != storageNodes)
            {
                var oldOs = storageNodes.Where(machine => machine.OperatingSystem.Version < new Version { Major = 6, Minor = 2 });
                if (oldOs.Count() != 0)
                {
                    yield return new ValidationMessage
                    {
                        Message = "Failover iSCSI storage only works with 2012 or greater",
                        TargetObject = string.Join(", ", from item in oldOs select item.Name),
                        Type = MessageType.Error
                    };
                }
            }            
        }
    }
}
