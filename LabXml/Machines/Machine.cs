using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Security;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class Machine
    {
        private string name;
        private long memory;
        private long minMemory;
        private long maxMemory;
        private int processors;
        private int diskSize;
        private List<NetworkAdapter> networkAdapters;
        private List<Role> roles;
        private string domainName;
        private bool isDomainJoined;
        private bool hasDomainJoined;
        private string unattendedXml;
        private User installationUser;
        private string userLocale;
        private string timeZone;
        private List<PostInstallationActivity> postInstallationActivity;
        private string productKey;
        private Path toolsPath;
        private string toolsPathDestination;
        private OperatingSystem operatingSystem;
        private List<Disk> disks;
        private VirtualizationHost hostType;
        private bool enableWindowsFirewall;
        private string autoLogonDomainName;
        private string autoLogonUserName;
        private string autoLogonPassword;
        private Hashtable azureProperties;
        private Hashtable hypervProperties;
        private SerializableDictionary<string, string> notes;
        private SerializableDictionary<string, string> internalNotes;
        private OperatingSystemType operatingSystemType;
        private bool gen2vmSupported;
        private LinuxType linuxType;
        private bool skipDeployment;

        public LinuxType LinuxType
        {
            get
            {
                if (System.Text.RegularExpressions.Regex.IsMatch(OperatingSystem.OperatingSystemName, "Windows"))
                {
                    return LinuxType.Unknown;
                }
                else if (System.Text.RegularExpressions.Regex.IsMatch(OperatingSystem.OperatingSystemName, "CentOS|Red Hat|Fedora"))
                {
                    return LinuxType.RedHat;
                }

                return LinuxType.SuSE;
            }
        }

        public string FriendlyName { get; set; }

        public bool Gen2VmSupported
        {
            get
            {
                return (OperatingSystem.Version >= new Version(6, 2, 0) || OperatingSystemType == OperatingSystemType.Linux) ? true : false;
            }
        }

        public string ResourceName
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(FriendlyName)) { return FriendlyName; } else { return Name; }
            }
        }
        public int LoadBalancerRdpPort { get; set; }
        public int LoadBalancerWinRmHttpPort { get; set; }
        public int LoadBalancerWinrmHttpsPort { get; set; }

        public List<string> LinuxPackageGroup { get; set; }

        public OperatingSystemType OperatingSystemType
        {
            get
            {
                return operatingSystem.OperatingSystemType;
            }
        }

        public int Processors
        {
            get { return processors; }
            set { processors = value; }
        }

        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        [XmlIgnore]
        public string FQDN
        {
            get
            {
                if (!string.IsNullOrEmpty(domainName))
                {
                    return string.Format("{0}.{1}", name, domainName);
                }
                else
                {
                    return name;
                }
            }
        }

        [XmlIgnore]
        public string DomainAccountName
        {
            get
            {
                if (!string.IsNullOrEmpty(domainName))
                {
                    var domainShortName = domainName.Split('.')[0];
                    return string.Format("{0}\\{1}", domainShortName, name);
                }
                else
                {
                    return name;
                }
            }
        }

        public long Memory
        {
            get { return memory; }
            set { memory = value; }
        }

        public long MinMemory
        {
            get { return minMemory; }
            set { minMemory = value; }
        }

        public long MaxMemory
        {
            get { return maxMemory; }
            set { maxMemory = value; }
        }

        [Obsolete("No longer used in V2. Member still defined due to compatibility.")]
        public MachineTypes Type
        {
            get { return MachineTypes.Unknown; }
            set { throw new NotImplementedException(); }
        }

        public int DiskSize
        {
            get { return diskSize; }
            set { diskSize = value; }
        }

        public string[] Network
        {
            get
            {
                if (networkAdapters.Count > 0)
                {
                    return networkAdapters.Select(na => na.VirtualSwitch.Name).ToArray();
                }
                else
                {
                    return new string[0];
                }
            }
        }

        public IPNetwork[] IpAddress
        {
            get
            {
                if (networkAdapters.Count > 0)
                {
                    return networkAdapters.SelectMany(na => na.Ipv4Address).ToArray();
                }
                else
                    return new IPNetwork[0];
            }
        }

        public string IpV4Address
        {
            get
            {
                return IpAddress[0].IpAddress.AddressAsString;
            }
        }

        [XmlArrayItem(ElementName = "NetworkAdapter")]
        public List<NetworkAdapter> NetworkAdapters
        {
            get { return networkAdapters; }
            set { networkAdapters = value; }
        }

        [XmlArrayItem(ElementName = "Role")]
        public List<Role> Roles
        {
            get { return roles; }
            set { roles = value; }
        }

        public string DomainName
        {
            get { return domainName; }
            set { domainName = value; }
        }

        public bool IsDomainJoined
        {
            get { return isDomainJoined; }
            set { isDomainJoined = value; }
        }

        public bool HasDomainJoined
        {
            get { return hasDomainJoined; }
            set { hasDomainJoined = value; }
        }

        public string UnattendedXml
        {
            get { return unattendedXml; }
            set { unattendedXml = value; }
        }

        public User InstallationUser
        {
            get { return installationUser; }
            set { installationUser = value; }
        }

        public Path ToolsPath
        {
            get { return toolsPath; }
            set { toolsPath = value; }
        }

        public string ToolsPathDestination
        {
            get { return toolsPathDestination; }
            set { toolsPathDestination = value; }
        }

        public string UserLocale
        {
            get { return userLocale; }
            set { userLocale = value; }
        }

        public string TimeZone
        {
            get { return timeZone; }
            set { timeZone = value; }
        }

        [XmlElement("PostInstallation")]
        public List<PostInstallationActivity> PostInstallationActivity
        {
            get { return postInstallationActivity; }
            set { postInstallationActivity = value; }
        }

        public string ProductKey
        {
            get { return productKey; }
            set { productKey = value; }
        }

        public OperatingSystem OperatingSystem
        {
            get { return operatingSystem; }
            set { operatingSystem = value; }
        }

        public List<Disk> Disks
        {
            get { return disks; }
            set { disks = value; }
        }

        public VirtualizationHost HostType
        {
            get { return hostType; }
            set { hostType = value; }
        }

        public bool EnableWindowsFirewall
        {
            get { return enableWindowsFirewall; }
            set { enableWindowsFirewall = value; }
        }

        public string AutoLogonDomainName
        {
            get { return autoLogonDomainName; }
            set { autoLogonDomainName = value; }
        }

        public string AutoLogonUserName
        {
            get { return autoLogonUserName; }
            set { autoLogonUserName = value; }
        }

        public string AutoLogonPassword
        {
            get { return autoLogonPassword; }
            set { autoLogonPassword = value; }
        }

        public Azure.AzureConnectionInfo AzureConnectionInfo {get; set;}

        public SerializableDictionary<string, string> AzureProperties
        {
            get
            {
                if (azureProperties != null)
                {
                    return azureProperties;
                }
                else
                {
                    return new System.Collections.Hashtable();
                }
            }
            set { azureProperties = value; }
        }

        public SerializableDictionary<string, string> HypervProperties
        {
            get
            {
                if (hypervProperties != null)
                {
                    return hypervProperties;
                }
                else
                {
                    return new System.Collections.Hashtable();
                }
            }
            set { hypervProperties = value; }
        }

        public SerializableDictionary<string, string> Notes
        {
            get { return notes; }
            set { notes = value; }
        }

        public SerializableDictionary<string, string> InternalNotes
        {
            get { return internalNotes; }
            set { internalNotes = value; }
        }

        public bool SkipDeployment
        {
            get { return skipDeployment; }
            set { skipDeployment = value; }
        }

        public Machine()
        {
            roles = new List<Role>();
            LinuxPackageGroup = new List<string>();
            postInstallationActivity = new List<PostInstallationActivity>();
            networkAdapters = new List<NetworkAdapter>();
            internalNotes = new SerializableDictionary<string, string>();
            notes = new SerializableDictionary<string, string>();
        }

        public override string ToString()
        {
            return name;
        }

        public PSCredential GetLocalCredential(bool Force = false)
        {
            var securePassword = new SecureString();

            foreach (var c in installationUser.Password)
            {
                securePassword.AppendChar(c);
            }

            var dcRoles = AutomatedLab.Roles.RootDC | AutomatedLab.Roles.FirstChildDC | AutomatedLab.Roles.DC;
            var dcRole = roles.Where(role => ((AutomatedLab.Roles)role.Name & dcRoles) == role.Name).FirstOrDefault();

            string userName = string.Empty;
            if (dcRole == null || Force)
            {
                //machine is not a domain controller, creating a local username 
                userName = OperatingSystemType == OperatingSystemType.Linux ? "root" : string.Format(@"{0}\{1}", name, installationUser.UserName);
            }
            else
            {
                //machine is a domain controller, hence there are no local accounts. Creating a domain username using the local installation user
                userName = string.Format(@"{0}\{1}", domainName, installationUser.UserName);
            }

            var cred = new PSCredential(userName, securePassword);

            return cred;
        }

        public PSCredential GetCredential(Lab lab)
        {
            if (isDomainJoined)
            {
                var domain = lab.Domains.Where(d => d.Name.ToLower() == domainName.ToLower()).FirstOrDefault();

                if (domain == null)
                {
                    throw new ArgumentException(string.Format("Domain could not be found: {0}", domainName));
                }

                return domain.GetCredential();
            }
            else
            {
                return GetLocalCredential();
            }
        }
    }
}
