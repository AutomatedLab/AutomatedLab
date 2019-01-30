using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class ProductKey
    {
        [XmlAttribute]
        public string OperatingSystemName { get; set; }

        [XmlAttribute]
        public string Key { get; set; }

        [XmlAttribute]
        public string Version { get; set; }

        public override string ToString()
        {
            return Key;
        }
    }
}
