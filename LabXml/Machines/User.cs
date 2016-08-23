using System;
using System.Management.Automation;
using System.Security;

namespace AutomatedLab
{
    [Serializable]
    public class User
    {
        private string userName;
        private string password;

        public string UserName
        {
            get { return userName; }
            set { userName = value; }
        }

        public string Password
        {
            get { return password; }
            set { password = value; }
        }

        public User()
        { }

        public User(string name, string password)
        {
            this.userName = name;
            this.password = password;
        }

        public PSCredential GetCredential()
        {
            var securePassword = new SecureString();
            securePassword.AppendString(password);

            return new PSCredential(userName, securePassword);
        }
    }
}
