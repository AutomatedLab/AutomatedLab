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
        private string azureRmProfilePath;        
        private string subscriptionFileContent;
        private List<AzureLocation> locations;
        private AzureRmStorageAccount defaultStorageAccount;
        private AzureRmResourceGroup defaultResourceGroup;
        private string defaultStorageAccountKey;
        private AzureLocation defaultLocation;
        private string vnetConfig;
        private List<AzureRmStorageAccount> storageAccounts;
        private List<AzureOSImage> vmImages;
        private List<AzureVirtualMachine> virtualMachines;
        private List<AzureRmVmSize> roleSizes;
        private List<AzureRmResourceGroup> resourceGroups;
        private List<string> vmDisks;
        private string defaultRoleSize;
        private string labSourcesStorageAccountName;
        private string labSourcesResourceGroupName;
        private int loadBalancerPortCounter;

        public int LoadBalancerPortCounter
        {
            get { return loadBalancerPortCounter; }
            set { loadBalancerPortCounter = value; }
        }

        public string AutoShutdownTime {get; set;}
        public string AutoShutdownTimeZone { get; set; }
        public bool AllowBastionHost {get; set; }

        public string LabSourcesResourceGroupName
        {
            get { return labSourcesResourceGroupName; }
            set { labSourcesResourceGroupName = value; }
        }


        public string LabSourcesStorageAccountName
        {
            get { return labSourcesStorageAccountName; }
            set { labSourcesStorageAccountName = value; }
        }

        public List<AzureRmStorageAccount> StorageAccounts
        {
            get { return storageAccounts; }
            set { storageAccounts = value; }
        }

        public string AzureProfilePath
        {
            get { return azureRmProfilePath; }
            set { azureRmProfilePath = value; }
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

        public AzureRmResourceGroup DefaultResourceGroup
        {
            get { return defaultResourceGroup; }
            set { defaultResourceGroup = value; }
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

        public List<AzureRmResourceGroup> ResourceGroups
        {
            get { return resourceGroups; }
            set { resourceGroups = NonEmptyList<AzureRmResourceGroup>(value); }
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
            locations = new List<AzureLocation>();
            storageAccounts = new List<AzureRmStorageAccount>();
            vmImages = new List<AzureOSImage>();
            roleSizes = new List<AzureRmVmSize>();
            resourceGroups = new List<AzureRmResourceGroup>();
            subscriptions = new List<AzureSubscription>();
            vmDisks = new List<string>();

            // Start port counter above well-known ports
            LoadBalancerPortCounter = 5000;
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