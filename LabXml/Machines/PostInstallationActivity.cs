using System;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class PostInstallationActivity
    {
        private Path dependencyFolder;
        private string scriptFileName;
        private string scriptFilePath;
        private bool keepFolder;
        private Path isoImage;
        private bool useCredSsp;
        private bool asJob;

        public Path DependencyFolder
        {
            get { return dependencyFolder; }
            set { dependencyFolder = value; }
        }

        public string ScriptFilePath
        {
            get { return scriptFilePath; }
            set
            {
                if (string.IsNullOrEmpty(scriptFileName))
                {
                    scriptFilePath = value;
                }
            }
        }

        public string ScriptFileName
        {
            get { return scriptFileName; }
            set
            {
                if (string.IsNullOrEmpty(scriptFilePath))
                {
                    scriptFileName = value;
                }
            }
        }

        public bool KeepFolder
        {
            get { return keepFolder; }
            set { keepFolder = value; }
        }

        [XmlElement(IsNullable = true)]
        public Path IsoImage
        {
            get { return isoImage; }
            set { isoImage = value; }
        }

        public bool UseCredSsp
        {
            get { return useCredSsp; }
            set { useCredSsp = value; }
        }

        public bool AsJob
        {
            get { return asJob; }
            set { asJob = value; }
        }
    }
}
