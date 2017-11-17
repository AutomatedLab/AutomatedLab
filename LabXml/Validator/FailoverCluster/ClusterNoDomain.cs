using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab.Validator.FailoverCluster
{
    class ClusterNoDomain : LabValidator, IValidate
    {
        public ClusterNoDomain()
        {
            messageContainer = RunValidation();
        }

        public override IEnumerable<ValidationMessage> Validate()
        {
            var failoverNodes = machines.Where(machine => machine.Roles.Select(role => role.Name).Contains(Roles.FailoverNode));

            Dictionary<string, List<Machine>> clusters = new Dictionary<string, List<Machine>>();

            foreach (var node in failoverNodes)
            {
                var tempNode = node.Roles.Where(r => r.Name.Equals(Roles.FailoverNode)).First();
                var clusterName = "ALCluster";
                if (tempNode.Properties.ContainsKey("ClusterName"))
                {
                    clusterName = node.Roles.Where(r => r.Name.Equals(Roles.FailoverNode)).First().Properties["ClusterName"].ToString();
                }

                if (!clusters.ContainsKey(clusterName))
                {
                    clusters.Add(clusterName, new List<Machine>());
                }

                clusters[clusterName].Add(node);
            }

            foreach (var cluster in clusters)
            {
                var domainCount = cluster.Value.Select(machine => machine.DomainName).Distinct().Count();

                if (domainCount == 1)
                {
                    continue;
                }

                foreach (var node in failoverNodes)
                {
                    if (node.OperatingSystem.Version >= new Version { Major = 10 })
                    {
                        continue;
                    }

                    yield return new ValidationMessage
                    {
                        Message = "Workgroup or multidomain clusters are only supported starting with Server 2016",
                        TargetObject = node.Name,
                        Type = MessageType.Error
                    };
                }
            }
        }
    }
}
