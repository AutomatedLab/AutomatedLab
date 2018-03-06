﻿using System;
using System.Collections.Generic;
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
        private SerializableDictionary<string, List<object>> properties;
        private bool doNotUseCredSsp;
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

        public SerializableDictionary<string, List<object>> Properties
        {
            get { return properties; }
            set { properties = value; }
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

        public PostInstallationActivity()
        {
            properties = new SerializableDictionary<string, List<object>>();
        }
    }
}
