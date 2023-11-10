using System;
using System.Collections.Generic;
using System.Xml.Serialization;

namespace AutomatedLab.Machines
{
    [Serializable]
    [XmlRoot(ElementName = "configuration")]
    public class MachineVmConnectConfig : XmlStore<MachineVmConnectConfig>
    {
        [XmlArray("Microsoft.Virtualization.Client.RdpOptions")]
        [XmlArrayItem(ElementName = "setting")]
        public List<MachineVmConnectRdpOptionSetting> Settings;

        public MachineVmConnectConfig()
        {
            Settings = new List<MachineVmConnectRdpOptionSetting>();
        }
    }

    [Serializable]    
    public class MachineVmConnectRdpOptionSetting
    {
        [XmlAttribute("name")]
        public string Name { get; set; }

        [XmlAttribute("type")]
        public string Type { get; set; }

        [XmlElement(ElementName = "value")]
        public string Value { get; set; }
    }

}
