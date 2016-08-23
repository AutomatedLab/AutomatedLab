using System;

namespace AutomatedLab
{
    [Serializable]
    public class LocalDisk
    {
        private char driveLetter;
        private string serial;
        private UInt32 signature;
        private double readSpeed;
        private double writeSpeed;

        public char DriveLetter
        {
            get { return driveLetter; }
            set { driveLetter = value; }
        }

        public string Serial
        {
            get { return serial; }
            set { serial = value; }
        }

        public UInt32 Signature
        {
            get { return signature; }
            set { signature = value; }
        }

        public double ReadSpeed
        {
            get { return readSpeed; }
            set { readSpeed = value; }
        }

        public double WriteSpeed
        {
            get { return writeSpeed; }
            set { writeSpeed = value; }
        }

        public string UniqueId
        {
            get { return string.Format("{0}-{1}-{2}", driveLetter, serial, signature); }
        }

        public double TotalSpeed
        {
            get { return readSpeed + writeSpeed; }
        }

        public LocalDisk()
        { }

        public LocalDisk(char driveLetter)
        {
            this.driveLetter = driveLetter;
        }

        public string Root
        {
            get { return string.Format("{0}:\\", driveLetter); }
        }

        public long FreeSpace
        {
            get
            {
                var driveInfo = new System.IO.DriveInfo(driveLetter.ToString());
                return driveInfo.TotalFreeSpace;
            }
        }

        public double FreeSpaceGb
        {
            get { return Math.Round(FreeSpace / Math.Pow(1024, 3), 2); }
        }

        public override string ToString()
        {
            return string.Format("{0}:", driveLetter.ToString());
        }

        public override bool Equals(object obj)
        {
            var disk = obj as LocalDisk;

            if (disk == null)
                return false;

            return UniqueId == disk.UniqueId;
        }

        public override int GetHashCode()
        {
            return UniqueId.GetHashCode();
        }
    }
}
