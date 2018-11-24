﻿using System;
using System.Xml.Serialization;
using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    [Serializable]
    public class OperatingSystem
    {
        private string operatingSystemName;
        private string operatingSystemImageName;
        private string operatingSystemImageDescription;
        private string isoPath;
        private string baseDiskPath;
        private Version version;
        private DateTime publishedDate;
        private long size;
        private string edition;
        private string installation;
        private int imageIndex;
        private Dictionary<string, string> azureToIsoName = new Dictionary<string, string>(){
            {"2008-R2-SP1", "Windows Server 2008 R2 Datacenter (Full Installation)" },
            {"2012-Datacenter", "Windows Server 2012 Datacenter (Server with a GUI)" },
            {"2012-R2-Datacenter", "Windows Server 2012 R2 Datacenter (Server with a GUI)" },
            {"2016-Datacenter", "Windows Server 2016 Datacenter (Desktop Experience)" },
            {"2016-Datacenter-Server-Core", "Windows Server 2016 Datacenter" },
            {"Datacenter-Core-1803-with-Containers-smalldisk", "Windows Server Datacenter" },
            {"Win81-Ent-N-x64", "Windows 8.1 Enterprise" },
            {"Windows-10-N-x64", "Windows 10 Enterprise" },
            {"Win7-SP1-Ent-N-x64", "Windows 7 Enterprise" },
            {"rs4-pro", "Windows 10 Pro" }
            };
        private Dictionary<string, string> isoNameToAzureSku;

        public string OperatingSystemName
        {
            get { return operatingSystemName; }
            set { operatingSystemName = value; }
        }

        public Version Version
        {
            get
            {
                if (version != null)
                {
                    return version;
                }
                else
                {
                    switch (VersionString)
                    {
                        case "2008":
                            return (IsR2 ? "6.1" : "6.0");
                        case "2012":
                            return (IsR2 ? "6.3" : "6.2");
                        case "2016":
                            return "10.0";
                        case "2019":
                            return "10.0";
                        case "7":
                            return "6.1";
                        case "8":
                            return "6.2";
                        case "8.1":
                            return "6.3";
                        case "10":
                            return "10.0";
                        case "":
                            if (operatingSystemName == "Windows Server Datacenter" |
                                operatingSystemName == "Windows Server Standard" |
                                operatingSystemName == "Windows Server Datacenter (Desktop Experience)" |
                                operatingSystemName == "Windows Server Standard (Desktop Experience)"
                                )
                                return "10.0";
                            throw new Exception("Operating System Version could not be retrieved");
                        default:
                            return VersionString;
                    }

                }
            }
            set { version = value; }
        }

        public DateTime PublishedDate
        {
            get { return publishedDate; }
            set { publishedDate = value; }
        }

        public long Size
        {
            get { return size; }
            set { size = value; }
        }

        public string Edition
        {
            get { return edition; }
            set { edition = value; }
        }

        public string Installation
        {
            get { return installation; }
            set { installation = value; }
        }

        public string AzureImageName
        {
            get
            {
                try
                {
                    return isoNameToAzureSku[OperatingSystemName];
                }
                catch (ArgumentNullException)
                {
                    // Key is null - can happen
                }
                catch (KeyNotFoundException)
                {
                    // OS not in dictionary - can happen
                }

                return string.Empty;
            }
        }

        public string VMWareImageName
        {
            get
            {
                //the VMWare templates must be provided by the VMWare infrastructure
                switch (operatingSystemName)
                {
                    case "Windows Server 2008 R2 Datacenter (Full Installation)":
                        return "AL_WindowsServer2008R2DataCenter";

                    case "Windows Server 2012 Datacenter (Server with a GUI)":
                        return "AL_WindowsServer2012DataCenter";

                    case "Windows Server 2012 R2 Datacenter (Server with a GUI)":
                        return "AL_WindowsServer2012R2DataCenter";

                    case "Windows Server vNext SERVERDATACENTER":
                        return "AL_WindowsServer10DataCenter";

                    default:
                        return string.Empty;
                }
            }
        }

        public string ProductKey
        {
            get
            {
                switch (operatingSystemName)
                {
                    //Windows 7
                    case "Windows 7 Professional":
                        return "FJ82H-XT6CR-J8D7P-XQJJ2-GPDD4";
                    case "Windows 7 Enterprise":
                        return "33PXH-7Y6KF-2VJC9-XBBR8-HVTHH";

                    //Windows 8
                    case "Windows 8 Pro":
                        return "NG4HW-VH26C-733KW-K6F98-J8CK4";
                    case "Windows 8 Enterprise":
                        return "32JNW-9KQ84-P47T8-D8GGY-CWCK7";

                    //Windows 8.1
                    case "Windows 8.1 Pro":
                        return "GCRJD-8NW9H-F2CDX-CCM8D-9D6T9";
                    case "Windows 8.1 Enterprise":
                        return "MHF9N-XY6XB-WVXMC-BTDCT-MKKG7";

                    //Windows 2008 new names
                    case "Windows Server 2008 R2 Standard (Full Installation)":
                        return "YC6KT-GKW9T-YTKYR-T4X34-R7VHC";
                    case "Windows Server 2008 R2 Standard (Server Core Installation)":
                        return "YC6KT-GKW9T-YTKYR-T4X34-R7VHC";
                    case "Windows Server 2008 R2 Datacenter (Full Installation)":
                        return "74YFP-3QFB3-KQT8W-PMXWJ-7M648";
                    case "Windows Server 2008 R2 Datacenter (Server Core Installation)":
                        return "74YFP-3QFB3-KQT8W-PMXWJ-7M648";

                    //Windows 2008 old names
                    case "Windows Server 2008 R2 SERVERSTANDARD":
                        return "YC6KT-GKW9T-YTKYR-T4X34-R7VHC";
                    case "Windows Server 2008 R2 SERVERSTANDARDCORE":
                        return "YC6KT-GKW9T-YTKYR-T4X34-R7VHC";
                    case "Windows Server 2008 R2 SERVERDATACENTER":
                        return "74YFP-3QFB3-KQT8W-PMXWJ-7M648";
                    case "Windows Server 2008 R2 SERVERDATACENTERCORE":
                        return "74YFP-3QFB3-KQT8W-PMXWJ-7M648";

                    //Windows Server 2012 new names
                    case "Windows Server 2012 Standard (Server Core Installation)":
                        return "XC9B7-NBPP2-83J2H-RHMBY-92BT4";
                    case "Windows Server 2012 Standard (Server with a GUI)":
                        return "XC9B7-NBPP2-83J2H-RHMBY-92BT4";
                    case "Windows Server 2012 Datacenter (Server Core Installation)":
                        return "48HP8-DN98B-MYWDG-T2DCC-8W83P";
                    case "Windows Server 2012 Datacenter (Server with a GUI)":
                        return "48HP8-DN98B-MYWDG-T2DCC-8W83P";

                    //Windows Server 2012 new names
                    case "Windows Server 2012 SERVERSTANDARDCORE":
                        return "XC9B7-NBPP2-83J2H-RHMBY-92BT4";
                    case "Windows Server 2012 SERVERSTANDARD":
                        return "XC9B7-NBPP2-83J2H-RHMBY-92BT4";
                    case "Windows Server 2012 SERVERDATACENTERCORE":
                        return "48HP8-DN98B-MYWDG-T2DCC-8W83P";
                    case "Windows Server 2012 SERVERDATACENTER":
                        return "48HP8-DN98B-MYWDG-T2DCC-8W83P";

                    //Windows Server 2012 R2 new names
                    case "Windows Server 2012 R2 Standard (Server Core Installation)":
                        return "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V";
                    case "Windows Server 2012 R2 Standard Evaluation (Server Core Installation)":
                        return "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V";

                    case "Windows Server 2012 R2 Standard (Server with a GUI)":
                        return "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V";
                    case "Windows Server 2012 R2 Standard Evaluation (Server with a GUI)":
                        return "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V";

                    case "Windows Server 2012 R2 Datacenter (Server Core Installation)":
                        return "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW";
                    case "Windows Server 2012 R2 Datacenter Evaluation (Server Core Installation)":
                        return "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW";

                    case "Windows Server 2012 R2 Datacenter (Server with a GUI)":
                        return "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW";
                    case "Windows Server 2012 R2 Datacenter Evaluation (Server with a GUI)":
                        return "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW";

                    //Windows Server 2012 R2 old names
                    case "Windows Server 2012 R2 SERVERSTANDARDCORE":
                        return "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V";
                    case "Windows Server 2012 R2 SERVERSTANDARD":
                        return "DBGBW-NPF86-BJVTX-K3WKJ-MTB6V";
                    case "Windows Server 2012 R2 SERVERDATACENTERCORE":
                        return "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW";
                    case "Windows Server 2012 R2 SERVERDATACENTER":
                        return "Y4TGP-NPTV9-HTC2H-7MGQ3-DV4TW";

                    //Windows 10
                    case "Windows 10 Pro":
                        return "W269N-WFGWX-YVC9B-4J6C9-T83GX";
                    case "Windows 10 Pro for Workstations":
                        return "W269N-WFGWX-YVC9B-4J6C9-T83GX";
                    case "Windows 10 Enterprise":
                        return "NPPR9-FWDCX-D2C8J-H872K-2YT43";
                    case "Windows 10 Enterprise Evaluation":
                        return "NPPR9-FWDCX-D2C8J-H872K-2YT43";
                    case "Windows 10 Enterprise Insider Preview":
                        return "NPPR9-FWDCX-D2C8J-H872K-2YT43";
                    case "Windows 10 Pro Insider Preview":
                        return "NPPR9-FWDCX-D2C8J-H872K-2YT43";
                    case "Windows 10 Enterprise 2015 LTSB":
                        return "WNMTR-4C88C-JK8YV-HQ7T2-76DF9";
                    case "Windows 10 Enterprise 2016 LTSB":
                        return "DCPHK-NFMTC-H88MJ-PFHPY-QJ4BJ";
                    case "Windows 10 Enterprise for Virtual Desktops":
                        return "CPWHC-NT2C7-VYW78-DHDB2-PG3GK";

                    //Windows Server 2016 new names
                    case "Windows Server 2016 Standard":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server 2016 Standard (Desktop Experience)":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";

                    case "Windows Server 2016 Datacenter":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";
                    case "Windows Server 2016 Datacenter (Desktop Experience)":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";

                    case "Windows Server 2016 Standard Evaluation":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server 2016 Standard Evaluation (Desktop Experience)":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";

                    case "Windows Server 2016 Datacenter Evaluation":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";
                    case "Windows Server 2016 Datacenter Evaluation (Desktop Experience)":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";

                    //Windows Server 2016 old names
                    case "Windows Server 2016 SERVERSTANDARDCORE":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server 2016 SERVERSTANDARD":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server 2016 SERVERDATACENTERCORE":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";
                    case "Windows Server 2016 SERVERDATACENTER":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";

                    // Windows Server 1709+ new names
                    case "Windows Server Standard":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server Standard (Desktop Experience)":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";

                    case "Windows Server Datacenter":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";
                    case "Windows Server Datacenter (Desktop Experience)":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";

                    // Windows Server 1709+ old names
                    case "Windows Server 2016 SERVERSTANDARDACORE":
                        return "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY";
                    case "Windows Server 2016 SERVERDATACENTERACORE":
                        return "CB7KF-BWN84-R7R2Y-793K2-8XDDG";

                    // Windows Server 2019 new names
                    case "Windows Server 2019 Standard (Desktop Experience)":
                        return "N69G4-B89J2-4G8F4-WWYCC-J464C";
                    case "Windows Server 2019 Datacenter (Desktop Experience)":
                        return "WMDGN-G9PQG-XVVXX-R3X43-63DFG";
                    case "Windows Server 2019 Standard":
                        return "N69G4-B89J2-4G8F4-WWYCC-J464C";
                    case "Windows Server 2019 Datacenter":
                        return "WMDGN-G9PQG-XVVXX-R3X43-63DFG";

                    default:
                        return string.Empty;
                }
            }
        }

        public string IsoPath
        {
            get { return isoPath; }
            set { isoPath = value; }
        }

        public string IsoName
        {
            get { return System.IO.Path.GetFileNameWithoutExtension(isoPath); }
        }

        public string BaseDiskPath
        {
            get { return baseDiskPath; }
            set { baseDiskPath = value; }
        }

        [XmlArrayItem(ElementName = "Package")]
        public List<String> LinuxPackageGroup { get; set; }
        public OperatingSystem()
        {
            LinuxPackageGroup = new List<String>();
            isoNameToAzureSku = azureToIsoName.ToDictionary(kp => kp.Value, kp => kp.Key);
        }

        public OperatingSystem(string azureSkuName, bool azure = true)
        {
            isoNameToAzureSku = azureToIsoName.ToDictionary(kp => kp.Value, kp => kp.Key);

            try
            {
                operatingSystemName = azureToIsoName[azureSkuName];
            }
            catch (ArgumentNullException)
            {
                // Key is null - can happen
            }
            catch (KeyNotFoundException)
            {
                // OS not in dictionary - can happen
            }
        }

        public OperatingSystem(string operatingSystemName)
        {
            isoNameToAzureSku = azureToIsoName.ToDictionary(kp => kp.Value, kp => kp.Key);
            this.operatingSystemName = operatingSystemName;
            LinuxPackageGroup = new List<String>();
            if (operatingSystemName.ToLower().Contains("windows server"))
            {
                installation = "Server";
            }
            else
            {
                installation = "Client";
            }
        }

        public OperatingSystem(string operatingSystemName, AutomatedLab.Version version)
            : this(operatingSystemName)
        {
            LinuxPackageGroup = new List<String>();
            this.version = version;
        }

        public OperatingSystem(string operatingSystemName, string isoPath)
            : this(operatingSystemName)
        {
            LinuxPackageGroup = new List<String>();
            this.isoPath = isoPath;
        }

        public OperatingSystem(string operatingSystemName, string isoPath, Version version)
            : this(operatingSystemName)
        {
            LinuxPackageGroup = new List<String>();
            this.isoPath = isoPath;
            this.version = version;
        }

        public OperatingSystem(string operatingSystemName, string isoPath, Version version, string imageName)
            : this(operatingSystemName)
        {
            LinuxPackageGroup = new List<String>();
            this.isoPath = isoPath;
            this.version = version;
            this.operatingSystemImageName = imageName;
        }

        public override string ToString()
        {
            return operatingSystemName;
        }

        public LinuxType LinuxType
        {
            get
            {
                return (System.Text.RegularExpressions.Regex.IsMatch(OperatingSystemName, "CentOS|Red Hat|Fedora")) ? LinuxType.RedHat : LinuxType.SuSE;
            }
        }
        public OperatingSystemType OperatingSystemType
        {
            get
            {
                return ((bool)(OperatingSystemName.Contains("Windows"))) ? OperatingSystemType.Windows : OperatingSystemType.Linux;
            }
        }
        public string OperatingSystemImageName
        {
            get { return operatingSystemImageName; }
            set { operatingSystemImageName = value; }
        }

        public string OperatingSystemImageDescription
        {
            get { return operatingSystemImageDescription; }
            set { operatingSystemImageDescription = value; }
        }

        public int ImageIndex
        {
            get { return imageIndex; }
            set { imageIndex = value; }
        }

        public override bool Equals(object obj)
        {
            var os = obj as OperatingSystem;

            if (os == null)
                return false;

            return operatingSystemName == os.operatingSystemName &&
                version == os.version &&
                edition == os.edition &&
                installation == os.installation;
        }

        public static bool operator >(OperatingSystem o1, OperatingSystem o2)
        {
            return o1.Version > o2.Version;
        }
        public static bool operator <(OperatingSystem o1, OperatingSystem o2)
        {
            return o1.Version < o2.Version;
        }

        public static implicit operator string(OperatingSystem os)
        {
            return os.ToString();
        }

        public override int GetHashCode()
        {
            return base.GetHashCode();
        }

        private string VersionString
        {
            get
            {
                var exp = @"(?:Windows Server )?(\d{4})(( )?R2)?|(?:Windows )?((\d){1,2}(\.\d)?)|(?:(CentOS |Fedora |Red Hat Enterprise Linux |openSUSE Leap |SUSE Linux Enterprise Server ))?(\d+\.?\d?)((?: )?SP\d)?";

                var match = System.Text.RegularExpressions.Regex.Match(operatingSystemName, exp, System.Text.RegularExpressions.RegexOptions.IgnoreCase);

                if (!string.IsNullOrEmpty(match.Groups[1].Value))
                {
                    return match.Groups[1].Value;
                }
                else if (!string.IsNullOrEmpty(match.Groups[4].Value))
                {
                    return match.Groups[4].Value;
                }
                else
                {
                    if (!string.IsNullOrEmpty(match.Groups[9].Value))
                    {
                        return $"{match.Groups[8].Value}.{match.Groups[9].Value[match.Groups[9].Value.Length - 1]}";
                    }
                    return match.Groups[8].Value;
                }
            }
        }

        private bool IsR2
        {
            get
            {
                var exp = @"(WS)?(?:\d{4}( )?)(?<IsR2>R2)";

                var match = System.Text.RegularExpressions.Regex.Match(operatingSystemName, exp);

                if (!string.IsNullOrEmpty(match.Groups["IsR2"].Value))
                {
                    return true;
                }
                else
                {
                    return false;
                }
            }
        }
    }
}
