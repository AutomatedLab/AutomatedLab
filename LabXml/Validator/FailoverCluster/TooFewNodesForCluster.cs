using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Xml;

namespace AutomatedLab
{
    /// <summary>
    /// This validator informs about all defined domains.
    /// </summary>
    public class TooFewNodesForCluster : LabValidator, IValidate
    {
        public TooFewNodesForCluster()
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
                    clusterName = tempNode.Properties["ClusterName"].ToString();
                }
                
                if (!clusters.ContainsKey(clusterName))
                {
                    clusters.Add(clusterName, new List<Machine>());
                }

                clusters[clusterName].Add(node);
            }

            foreach (var cluster in clusters)
            {
                if (cluster.Value.Count < 2)
                {
                    yield return new ValidationMessage
                    {
                        Message = $"Too few nodes {cluster.Value.Count} for cluster {cluster.Key}",
                        TargetObject = cluster.Key,
                        Type = MessageType.Error
                    };
                }
            }
        }
    }
}