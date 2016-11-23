using System;
using System.Collections.Generic;
using AutomatedLab.Azure;

namespace AutomatedLab
{
    [Serializable]
    public class AzureSettings
    {
        private List<AzureSubscription> subscriptions;
        private AzureSubscription defaultSubscription;
        private string subscriptionFileContent;
        private List<AzureLocation> locations;
        private AzureRmStorageAccount defaultStorageAccount;
        private string defaultStorageAccountKey;
        private AzureLocation defaultLocation;
        private string vnetConfig;
        private List<AzureRmStorageAccount> storageAccounts;
        private List<AzureOSImage> vmImages;
        private List<AzureVirtualMachine> virtualMachines;
        private List<AzureRmVmSize> roleSizes;
        private List<AzureResourceGroup> services;
        private List<string> vmDisks;
        private string defaultRoleSize;        

        public List<AzureRmStorageAccount> StorageAccounts
        {
            get { return storageAccounts; }
            set { storageAccounts = value; }
        }

        public string SubscriptionFileContent
        {
            get { return subscriptionFileContent; }
            set { subscriptionFileContent = value; }
        }

        public string VnetConfig
        {
            get { return vnetConfig; }
            set { vnetConfig = value; }
        }

        public AzureLocation DefaultLocation
        {
            get { return defaultLocation; }
            set { defaultLocation = value; }
        }

        public string DefaultStorageAccountKey
        {
            get { return defaultStorageAccountKey; }
            set { defaultStorageAccountKey = value; }
        }

        public List<AzureOSImage> VmImages
        {
            get { return vmImages; }
            set { vmImages = value; }
        }

        public List<AzureVirtualMachine> VirtualMachines
        {
            get { return virtualMachines; }
            set { virtualMachines = value; }
        }

        public AzureRmStorageAccount DefaultStorageAccount
        {
            get { return defaultStorageAccount; }
            set { defaultStorageAccount = value; }
        }

        public List<AzureSubscription> Subscriptions
        {
            get { return subscriptions; }
            set { subscriptions = NonEmptyList<AzureSubscription>(value); }
        }

        public AzureSubscription DefaultSubscription
        {
            get { return defaultSubscription; }
            set { defaultSubscription = value; }
        }

        public List<AzureLocation> Locations
        {
            get { return locations; }
            set { locations = value; }
        }

        public List<AzureRmVmSize> RoleSizes
        {
            get { return roleSizes; }
            set { roleSizes = value; }
        }

        public List<AzureResourceGroup> Services
        {
            get { return services; }
            set { services = NonEmptyList<AzureResourceGroup>(value); }
        }

        public List<string> VmDisks
        {
            get { return vmDisks; }
            set { vmDisks = value; }
        }

        public string DefaultRoleSize
        {
            get { return defaultRoleSize; }
            set { defaultRoleSize = value; }
        }

        public AzureSettings()
        {
            this.locations = new List<AzureLocation>();
            this.storageAccounts = new List<AzureRmStorageAccount>();
            this.vmImages = new List<AzureOSImage>();
            this.roleSizes = new List<AzureRmVmSize>();
            this.services = new List<AzureResourceGroup>();
            this.subscriptions = new List<AzureSubscription>();
            this.vmDisks = new List<string>();
        }

        protected List<T> NonEmptyList<T>(List<T> value)
        {
            if (value == null)
                return new List<T>();
            else
                return value;
        }
    }
}