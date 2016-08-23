using System;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class VMWareConfiguration
    {
        private string dataCenterName;
        private string dataStoreName;
        private string resourcePoolName;
        private string clusterName;
        private string vCenterServerName;
        private string credential;

        private object dataCenter;
        private object network;
        private object dataStore;
        private object resourcePool;
        private object cluster;

        public string DataCenterName
        {
            get { return dataCenterName; }
            set { dataCenterName = value; }
        }

        public string DataStoreName
        {
            get { return dataStoreName; }
            set { dataStoreName = value; }
        }

        public string ResourcePoolName
        {
            get { return resourcePoolName; }
            set { resourcePoolName = value; }
        }

        public string ClusterName
        {
            get { return clusterName; }
            set { clusterName = value; }
        }

        public string VCenterServerName
        {
            get { return vCenterServerName; }
            set { vCenterServerName = value; }
        }

        public string Credential
        {
            get { return credential; }
            set { credential = value; }
        }

        [XmlIgnore]
        public object DataCenter
        {
            get { return dataCenter; }
            set { dataCenter = value; }
        }

        [XmlIgnore]
        public object Network
        {
            get { return network; }
            set { network = value; }
        }

        [XmlIgnore]
        public object DataStore
        {
            get { return dataStore; }
            set { dataStore = value; }
        }

        [XmlIgnore]
        public object ResourcePool
        {
            get { return resourcePool; }
            set { resourcePool = value; }
        }

        [XmlIgnore]
        public object Cluster
        {
            get { return cluster; }
            set { cluster = value; }
        }
    }
}