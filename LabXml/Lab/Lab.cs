using System;
using System.Collections.Generic;
using System.Xml.Serialization;
using System.Linq;

namespace AutomatedLab
{
    [Serializable]
    public class Sources
    {
        private List<IsoImage> isos;
        private Path unattendedXml;

        public List<IsoImage> ISOs
        {
            get { return isos; }
            set { isos = value; }
        }

        [XmlIgnore]
        public List<OperatingSystem> AvailableOperatingSystems
        {
            get { return isos.Cast<IsoImage>().SelectMany(iso => iso.OperatingSystems).ToList(); }
        }

        public Path UnattendedXml
        {
            get { return unattendedXml; }
            set { unattendedXml = value; }
        }

        public Sources()
        {
            isos = new List<IsoImage>();
        }
    }

    [Serializable]
    public class Target
    {
        private string path;
        private int referenceDiskSizeInGB;

        [XmlAttribute]
        public string Path
        {
            get { return path; }
            set { path = value; }
        }

        public int ReferenceDiskSizeInGB
        {
            get { return referenceDiskSizeInGB; }
            set { referenceDiskSizeInGB = value; }
        }
    }

    [Serializable]
    public class MachineDefinitionFile
    {
        [XmlAttribute()]
        public string Path { get; set; }
    }

    [Serializable]
    public class DiskDefinitionFile
    {
        [XmlAttribute()]
        public string Path { get; set; }
    }

    [Serializable]
    public class Lab : XmlStore<Lab>
    {
        private string name;
        private List<Domain> domains;
        private List<Machine> machines;
        private List<Disk> disks;
        private List<VirtualNetwork> virtualNetworks;
        private List<DiskDefinitionFile> diskDefinitionFiles;
        private List<MachineDefinitionFile> machineDefinitionFiles;
        private Sources sources;
        private Target target;
        private string labFilePath;
        private long maxMemory;
        private bool useStaticMemory;
        private OperatingSystem defaultOperatingSystem;
        private string defaultVirtualizationEngine;
        private User defaultInstallationUserCredential;
        private SerializableDictionary<string, string> notes;

        private AzureSettings azureSettings;
        private VMWareConfiguration vmwareSettings;

        private Azure.AzureRm azureResources;

        public List<Disk> Disks
        {
            get { return disks; }
            set { disks = value; }
        }

        public List<Machine> Machines
        {
            get { return machines; }
            set { machines = value; }
        }

        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        public List<Domain> Domains
        {
            get { return domains; }
            set { domains = value; }
        }

        public List<MachineDefinitionFile> MachineDefinitionFiles
        {
            get { return machineDefinitionFiles; }
            set { machineDefinitionFiles = value; }
        }

        public Sources Sources
        {
            get { return sources; }
            set { sources = value; }
        }

        public Target Target
        {
            get { return target; }
            set { target = value; }
        }

        public List<VirtualNetwork> VirtualNetworks
        {
            get { return virtualNetworks; }
            set { virtualNetworks = value; }
        }

        public string LabFilePath
        {
            get { return labFilePath; }
            set { labFilePath = value; }
        }

        public string LabPath
        {
            get { return System.IO.Path.GetDirectoryName(labFilePath); }
        }

        public long MaxMemory
        {
            get { return maxMemory; }
            set { maxMemory = value; }
        }
        public bool UseStaticMemory
        {
            get { return useStaticMemory; }
            set { useStaticMemory = value; }
        }

        public OperatingSystem DefaultOperatingSystem
        {
            get { return defaultOperatingSystem; }
            set { defaultOperatingSystem = value; }
        }

        public string DefaultVirtualizationEngine
        {
            get { return defaultVirtualizationEngine; }
            set { defaultVirtualizationEngine = value; }
        }

        public User DefaultInstallationCredential
        {
            get { return defaultInstallationUserCredential; }
            set { defaultInstallationUserCredential = value; }
        }

        public SerializableDictionary<string, string> Notes
        {
            get { return notes; }
            set { notes = value; }
        }

        public List<DiskDefinitionFile> DiskDefinitionFiles
        {
            get { return diskDefinitionFiles; }
            set { diskDefinitionFiles = value; }
        }

        public AzureSettings AzureSettings
        {
            get { return azureSettings; }
            set { azureSettings = value; }
        }

        public VMWareConfiguration VMWareSettings
        {
            get { return vmwareSettings; }
            set { vmwareSettings = value; }
        }

        public Azure.AzureRm AzureResources
        {
            get { return azureResources; }
            set { azureResources = value; }
        }

        public Lab()
        {
            sources = new Sources();
            target = new Target();

            domains = new List<Domain>();
            machineDefinitionFiles = new List<MachineDefinitionFile>();
            diskDefinitionFiles = new List<DiskDefinitionFile>();

            sources.ISOs = new List<IsoImage>();
            virtualNetworks = new List<VirtualNetwork>();
            notes = new SerializableDictionary<string, string>();

            azureResources = new Azure.AzureRm();
        }

        public bool IsRootDomain(string domainName)
        {
            var rootDCs = Machines.Where(m => m.Roles.Where(r => r.Name == Roles.RootDC).Count() == 1);

            if (rootDCs.Where(m => m.DomainName.ToLower() == domainName.ToLower()).Count() == 1)
                return true;
            else
                return false;
        }

        public Domain GetParentDomain(string domainName)
        {
            domainName = domainName.ToLower();

            if (Domains.Where(d => d.Name.ToLower() == domainName).Count() == 0)
                throw new ArgumentException($"The domain {domainName} could not be found in the lab.");
            
            var firstChildDcs = Machines.Where(m => m.Roles.Where(r => r.Name == Roles.FirstChildDC).Count() == 1);

            if (IsRootDomain(domainName))
            {
                return domains.Where(d => d.Name.ToLower() == domainName.ToLower()).FirstOrDefault();
            }
            else
            {
                var parentDomainName = firstChildDcs.Where(m => m.DomainName.ToLower() == domainName.ToLower()).FirstOrDefault().Roles.Where(r => r.Name == Roles.FirstChildDC).FirstOrDefault().Properties["ParentDomain"];
                return domains.Where(d => d.Name.ToLower() == parentDomainName.ToLower()).FirstOrDefault();
            }
        }
    }
}