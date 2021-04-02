using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class InstallationActivity
    {
        private Path dependencyFolder;
        private string scriptFileName;
        private string scriptFilePath;
        private bool keepFolder;
        private Path isoImage;
        private bool isCustomRole;
        private bool doNotUseCredSsp;
        private bool asJob;

        // Serialized list of PSVariable
        public string SerializedVariables { get; set; }

        // Serialized list of PSFunctionInfo
        public string SerializedFunctions { get; set; }

        // Serialized hashtable
        public string SerializedProperties { get; set; }

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

        public bool IsCustomRole
        {
            get { return isCustomRole; }
            set { isCustomRole = value; }
        }

        public string RoleName
        {
            get
            {
                if (!string.IsNullOrEmpty(scriptFileName))
                    return ScriptFileName.Split('.')[0];
                else
                    return string.Empty;
            }
        }

        public bool DoNotUseCredSsp
        {
            get { return doNotUseCredSsp; }
            set { doNotUseCredSsp = value; }
        }

        public bool AsJob
        {
            get { return asJob; }
            set { asJob = value; }
        }

        public override string ToString()
        {
            return RoleName;
        }
    }
}