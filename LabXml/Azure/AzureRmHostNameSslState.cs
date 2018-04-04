using System;

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
        public SslState? SslState { get; set; } //System.Nullable[Microsoft.Azure.Management.WebSites.Models.SslState]
        public string Thumbprint { get; set; }
        public bool? ToUpdate { get; set; }
        public string VirtualIP { get; set; }

        public override string ToString()
        {
            return Name;
        }
    }
}