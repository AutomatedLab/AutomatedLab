using System;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class Domain
    {
        private string name;

        [XmlAttribute]
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        private User administrator;

        public User Administrator
        {
            get { return administrator; }
            set { administrator = value; }
        }

        public System.Management.Automation.PSCredential GetCredential()
        {
            var userName = string.Format(@"{0}\{1}", name, Administrator.UserName);
            var securePassword = new System.Security.SecureString();
            securePassword.AppendString(Administrator.Password);

            var cred = new System.Management.Automation.PSCredential(userName, securePassword);

            return cred;
        }

        public override string ToString()
        {
            return name;
        }
    }
}
