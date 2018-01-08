using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AutomatedLab.Azure
{
    public enum SslState
    {
        Disabled = 0,
        SniEnabled = 1,
        IpBasedEnabled = 2
    }

    [Serializable]
    public class AzureRmHostNameSslState : CopiedObject<AzureRmHostNameSslState>
    {
        public string Name { get; set; }

        public int? SslState { get; set; } //System.Nullable[Microsoft.Azure.Management.WebSites.Models.SslState]


        public string Thumbprint { get; set; }

        public bool? ToUpdate { get; set; }

        public string VirtualIP { get; set; }

        public static AzureRmHostNameSslState Create(object input)
        {
            return Create<AzureRmHostNameSslState>(input);
        }

        public static IEnumerable<AzureRmHostNameSslState> Create(object[] input)
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create<AzureRmHostNameSslState>(item);
                }
            }
            else
            {
                yield break;
            }
        }

        public override string ToString()
        {
            return Name;
        }
    }
}