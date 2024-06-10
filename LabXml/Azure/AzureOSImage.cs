using System;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class AzureOSImage : CopiedObject<AzureOSImage>
    {
        public string Id { get; set; }
        public string Location { get; set; }
        public string Offer { get; set; }
        public string PublisherName { get; set; }
        public string Skus { get; set; }
        public string Version { get; set; }
        public string HyperVGeneration { get; set; }
        public string AutomatedLabOperatingSystemName { get; private set; }

        public AzureOSImage()
        {
            AutomatedLabOperatingSystemName = OsNameFromAzureString($"{Skus}_{PublisherName}");
        }

        public override string ToString()
        {
            return Offer;
        }

        private string OsNameFromAzureString(string azureSkuName)
        {
            // Return OS name AutomatedLab uses from one of the many, many, Azure SKU names
            switch (azureSkuName.ToLower())
            {
                case "windows-server-2022-azure-edition-preview-core_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "windows-server-2022-g2_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "windows-server-vnext-azure-edition_microsoftwindowsserver":
                    return "Windows Server 2025 Datacenter (Desktop Experience)";
                case "windows-server-vnext-azure-edition-core_microsoftwindowsserver":
                    return "Windows Server 2025 Datacenter";
                case "2012-datacenter_microsoftwindowsserver":
                    return "Windows Server 2012 Datacenter (Server with a GUI)";
                case "2012-datacenter-gensecond_microsoftwindowsserver":
                    return "Windows Server 2012 Datacenter (Server with a GUI)";
                case "2012-r2-datacenter_microsoftwindowsserver":
                    return "Windows Server 2012 R2 Datacenter (Server with a GUI)";
                case "2012-r2-datacenter-gensecond_microsoftwindowsserver":
                    return "Windows Server R2 2012 Datacenter (Server with a GUI)";
                case "2016-datacenter_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter (Desktop Experience)";
                case "2016-datacenter-gensecond_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter (Desktop Experience)";
                case "2016-datacenter-server-core_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter";
                case "2016-datacenter-server-core-g2_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter";
                case "2019-datacenter_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter (Desktop Experience)";
                case "2019-datacenter-core_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter";
                case "2019-datacenter-core-g2_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter";
                case "2019-datacenter-gensecond_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter (Desktop Experience)";
                case "2019-datacenter-gs_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter";
                case "2019-datacenter-gs-g2_microsoftwindowsserver":
                    return "Windows Server 2019 Datacenter";
                case "2022-datacenter_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "2022-datacenter-azure-edition_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "2022-datacenter-azure-edition-core_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "2022-datacenter-azure-edition-hotpatch_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "2022-datacenter-core_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "2022-datacenter-core-g2_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "2022-datacenter-g2_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter (Desktop Experience)";
                case "23h2-datacenter-core_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "23h2-datacenter-core-g2_microsoftwindowsserver":
                    return "Windows Server 2022 Datacenter";
                case "2016-datacenter-gen2_microsoftwindowsserver":
                    return "Windows Server 2016 Datacenter (Desktop Experience)";
                case "20_04-lts_canonical":
                    return "Ubuntu Server 20.04 LTS \"Focal Fossa\"";
                case "20_04-lts-gen2_canonical":
                    return "Ubuntu Server 20.04 LTS \"Focal Fossa\"";
                case "20_10-gen2_canonical":
                    return "Ubuntu Server 20.10 \"Groovy Gorilla\"";
                case "22_04-lts_canonical":
                    return "Ubuntu Server 22.04 LTS \"Jammy Jellyfish\"";
                case "22_04-lts-gen2_canonical":
                    return "Ubuntu Server 22.04 LTS \"Jammy Jellyfish\"";
                case "23_04_canonical":
                    return "Ubuntu Server 23.04 \"Lunar Lobster\"";
                case "23_04-gen2_canonical":
                    return "Ubuntu Server 23.04 \"Lunar Lobster\"";
                case "23_10_canonical":
                    return "Ubuntu Server 23.10 \"Mantic Minotaur\"";
                case "23_10-gen2_canonical":
                    return "Ubuntu Server 23.10 \"Mantic Minotaur\"";
                case "7.4_redhat":
                    return "Red Hat Enterprise Linux 7.4";
                case "7.5_redhat":
                    return "Red Hat Enterprise Linux 7.5";
                case "7.6_redhat":
                    return "Red Hat Enterprise Linux 7.6";
                case "7.7_redhat":
                    return "Red Hat Enterprise Linux 7.7";
                case "7.8_redhat":
                    return "Red Hat Enterprise Linux 7.8";
                case "74-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.4";
                case "75-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.5";
                case "76-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.6";
                case "77-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.7";
                case "78-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.8";
                case "79-gen2_redhat":
                    return "Red Hat Enterprise Linux 7.9";
                case "7_9_redhat":
                    return "Red Hat Enterprise Linux 7.9";
                case "8_redhat":
                    return "Red Hat Enterprise Linux 8.0";
                case "8.1_redhat":
                    return "Red Hat Enterprise Linux 8.1";
                case "8.2_redhat":
                    return "Red Hat Enterprise Linux 8.2";
                case "810-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.10";
                case "81gen2_redhat":
                    return "Red Hat Enterprise Linux 8.1";
                case "82gen2_redhat":
                    return "Red Hat Enterprise Linux 8.2";
                case "83-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.3";
                case "84-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.4";
                case "85-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.5";
                case "86-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.6";
                case "87-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.7";
                case "88-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.8";
                case "89-gen2_redhat":
                    return "Red Hat Enterprise Linux 8.9";
                case "8_10_redhat":
                    return "Red Hat Enterprise Linux 8.10";
                case "8_3_redhat":
                    return "Red Hat Enterprise Linux 8.3";
                case "8_4_redhat":
                    return "Red Hat Enterprise Linux 8.4";
                case "8_5_redhat":
                    return "Red Hat Enterprise Linux 8.5";
                case "8_6_redhat":
                    return "Red Hat Enterprise Linux 8.6";
                case "8_7_redhat":
                    return "Red Hat Enterprise Linux 8.7";
                case "8_8_redhat":
                    return "Red Hat Enterprise Linux 8.8";
                case "8_9_redhat":
                    return "Red Hat Enterprise Linux 8.9";
                case "90-gen2_redhat":
                    return "Red Hat Enterprise Linux 9.0";
                case "91-gen2_redhat":
                    return "Red Hat Enterprise Linux 9.1";
                case "92-gen2_redhat":
                    return "Red Hat Enterprise Linux 9.2";
                case "93-gen2_redhat":
                    return "Red Hat Enterprise Linux 9.3";
                case "94_gen2_redhat":
                    return "Red Hat Enterprise Linux 9.4";
                case "9_0_redhat":
                    return "Red Hat Enterprise Linux 9.0";
                case "9_1_redhat":
                    return "Red Hat Enterprise Linux 9.1";
                case "9_2_redhat":
                    return "Red Hat Enterprise Linux 9.2";
                case "9_3_redhat":
                    return "Red Hat Enterprise Linux 9.3";
                case "9_4_redhat":
                    return "Red Hat Enterprise Linux 9.4";
                case "6.10_openlogic":
                    return "CentOS 6.10";
                case "6.9_openlogic":
                    return "CentOS 6.9";
                case "7.3_openlogic":
                    return "CentOS 7.3";
                case "7.4_openlogic":
                    return "CentOS 7.4";
                case "7.5_openlogic":
                    return "CentOS 7.5";
                case "7.6_openlogic":
                    return "CentOS 7.6";
                case "7.7_openlogic":
                    return "CentOS 7.7";
                case "7_4_openlogic":
                    return "CentOS 7.4";
                case "7_4-gen2_openlogic":
                    return "CentOS 7.4";
                case "7_5-gen2_openlogic":
                    return "CentOS 7.5";
                case "7_6-gen2_openlogic":
                    return "CentOS 7.6";
                case "7_7-gen2_openlogic":
                    return "CentOS 7.7";
                case "7_8_openlogic":
                    return "CentOS 7.8";
                case "7_8-gen2_openlogic":
                    return "CentOS 7.8";
                case "7_9_openlogic":
                    return "CentOS 7.9";
                case "7_9-gen2_openlogic":
                    return "CentOS 7.9";
                case "8.0_openlogic":
                    return "CentOS 8.0";
                case "8_0-gen2_openlogic":
                    return "CentOS 8.0";
                case "8_1_openlogic":
                    return "CentOS 8.1";
                case "8_1-gen2_openlogic":
                    return "CentOS 8.1";
                case "8_2_openlogic":
                    return "CentOS 8.2";
                case "8_2-gen2_openlogic":
                    return "CentOS 8.2";
                case "8_3_openlogic":
                    return "CentOS 8.3";
                case "8_3-gen2_openlogic":
                    return "CentOS 8.3";
                case "8_4_openlogic":
                    return "CentOS 8.4";
                case "8_4-gen2_openlogic":
                    return "CentOS 8.4";
                case "8_5_openlogic":
                    return "CentOS 8.5";
                case "8_5-gen2_openlogic":
                    return "CentOS 8.5";
                case "kali-2023-3_kali-linux":
                    return "Kali Linux 2023.3";
                case "kali-2023-4_kali-linux":
                    return "Kali Linux 2023.4";
                case "19h1-ent-gensecond_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "19h1-entn-gensecond_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "19h1-pro-gensecond_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "19h1-pron-gensecond_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "19h2-pro-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "19h2-pron-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "20h2-ent_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "20h2-ent-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "20h2-entn_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "20h2-entn-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs1-enterprise_microsoftwindowsdesktop": // 1607
                    return "Windows 10 Enterprise";
                case "rs1-enterprise-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "rs1-enterprisen_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs1-enterprisen-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs5-enterprise_microsoftwindowsdesktop": // 1809
                    return "Windows 10 Enterprise";
                case "rs5-enterprise-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "rs5-enterprise-standard-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "rs5-enterprisen_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs5-enterprisen-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "rs5-enterprisen-standard-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-21h2-ent_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "win10-21h2-ent-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "win10-21h2-ent-ltsc_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise LTSC";
                case "win10-21h2-ent-ltsc-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise LTSC";
                case "win10-21h2-entn_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-21h2-entn-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-21h2-entn-ltsc_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N LTSC";
                case "win10-21h2-entn-ltsc-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N LTSC";
                case "win10-21h2-pro_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "win10-21h2-pro-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "win10-21h2-pron_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "win10-21h2-pron-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "win10-22h2-ent_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "win10-22h2-ent-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise";
                case "win10-22h2-entn_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-22h2-entn-g2_microsoftwindowsdesktop":
                    return "Windows 10 Enterprise N";
                case "win10-22h2-pro_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "win10-22h2-pro-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro";
                case "win10-22h2-pron_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "win10-22h2-pron-g2_microsoftwindowsdesktop":
                    return "Windows 10 Pro N";
                case "win11-21h2-entn_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise N";
                case "win11-21h2-pron_microsoftwindowsdesktop":
                    return "Windows 11 Pro N";
                case "win11-22h2-entn_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise N";
                case "win11-22h2-pron_microsoftwindowsdesktop":
                    return "Windows 11 Pro N";
                case "win11-23h2-entn_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise N";
                case "win11-23h2-pron_microsoftwindowsdesktop":
                    return "Windows 11 Pro N";
                case "win11-24h2-entn_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise N";
                case "win11-24h2-pron_microsoftwindowsdesktop":
                    return "Windows 11 Pro N";
                case "win11-21h2-ent_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise";
                case "win11-21h2-pro_microsoftwindowsdesktop":
                    return "Windows 11 Pro";
                case "win11-22h2-ent_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise";
                case "win11-22h2-pro_microsoftwindowsdesktop":
                    return "Windows 11 Pro";
                case "win11-23h2-ent_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise";
                case "win11-23h2-pro_microsoftwindowsdesktop":
                    return "Windows 11 Pro";
                case "win11-24h2-ent_microsoftwindowsdesktop":
                    return "Windows 11 Enterprise";
                case "win11-24h2-pro_microsoftwindowsdesktop":
                    return "Windows 11 Pro";
                default:
                    return string.Empty;
            }
        }
    }
}
