using System;
using System.Linq;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class Role
    {
        private Roles name;
        private SerializableDictionary<string, string> properties;

        [XmlAttribute]
        public Roles Name
        {
            get { return name; }
            set { name = value; }
        }

        public SerializableDictionary<string, string> Properties
        {
            get { return properties; }
            set { properties = value; }
        }

        public override string ToString()
        {
            return name.ToString();
        }

        public Role()
        {
            properties = new SerializableDictionary<string, string>();
        }

        public static implicit operator Role(string roleName)
        {
            roleName = Enum.GetNames(typeof(Roles)).Where(name => !Convert.ToBoolean((String.Compare(name, roleName, true)))).FirstOrDefault(); ;

            if (!Enum.IsDefined(typeof(Roles), roleName))
                throw new ArgumentException(string.Format("The role '{0}' is not defined", roleName));

            var r = new Role();
            r.name = (Roles)Enum.Parse(typeof(Roles), roleName);
            return r;
        }
    }
}
