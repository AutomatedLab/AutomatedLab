using System;
using System.Collections.Generic;

namespace AutomatedLab
{
    [Serializable]
    public class IsoImage
    {
        private string name;
        private string path;
        private long size;
        private MachineTypes? imageType;
        private string referenceDisk;
        private List<OperatingSystem> operatingSystems;

        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        public string Path
        {
            get { return path; }
            set { path = value; }
        }

        public long Size
        {
            get { return size; }
            set { size = value; }
        }

        public override string ToString()
        {
            return name;
        }

        public override bool Equals(object obj)
        {
            var iso = obj as IsoImage;

            if (iso == null)
                return false;

            return path == iso.path & size == iso.size;
        }

        public override int GetHashCode()
        {
            return path.GetHashCode();
        }

        [Obsolete("No longer used in V2. Member still defined due to compatibility.")]
        public MachineTypes? ImageType
        {
            get { return imageType; }
            set { imageType = value; }
        }

        public string ReferenceDisk
        {
            get { return referenceDisk; }
            set { referenceDisk = value; }
        }

        public List<OperatingSystem> OperatingSystems
        {
            get { return operatingSystems; }
            set { operatingSystems = value; }
        }

        public bool IsOperatingSystem
        {
            get { return operatingSystems.Count > 0; }
        }

        public IsoImage()
        {
            operatingSystems = new ListXmlStore<OperatingSystem>();
        }
    }
}