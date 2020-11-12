using System;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureConnectionInfo
    {
        public string ComputerName { get; set; }
        public string DnsName { get; set; }
        public string HttpsName { get; set; }
        public string VIP { get; set; }
        public int Port { get; set; }
        public int HttpsPort { get; set; }
        public int RdpPort { get; set; }
        public string ResourceGroupName { get; set; }
    }
}
