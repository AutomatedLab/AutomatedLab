/// <summary>
/// Serializable version of the System.Version class.
/// </summary>
using System;
using System.Globalization;

namespace AutomatedLab
{
    [Serializable]
    public class Version : ICloneable, IComparable
    {
        private int major;
        private int minor;
        private int build;
        private int revision;
        /// <summary>
        /// Gets the major.
        /// </summary>
        /// <value></value>
        public int Major
        {
            get { return major; }
            set { major = value; }
        }
        /// <summary>
        /// Gets the minor.
        /// </summary>
        /// <value></value>
        public int Minor
        {
            get { return minor; }
            set { minor = value; }
        }
        /// <summary>
        /// Gets the build.
        /// </summary>
        /// <value></value>
        public int Build
        {
            get { return build; }
            set { build = value; }
        }
        /// <summary>
        /// Gets the revision.
        /// </summary>
        /// <value></value>
        public int Revision
        {
            get { return revision; }
            set { revision = value; }
        }
        /// <summary>
        /// Creates a new <see cref="Version"/> instance.
        /// </summary>
        public Version()
        {
            build = -1;
            revision = -1;
            major = 0;
            minor = 0;
        }
        /// <summary>
        /// Creates a new <see cref="Version"/> instance.
        /// </summary>
        /// <param name="version">Version.</param>
        public Version(string version)
        {
            build = -1;
            revision = -1;
            if (version == null)
            {
                throw new ArgumentNullException("version");
            }
            char[] chArray1 = new char[1] { '.' };
            string[] textArray1 = version.Split(chArray1);
            int num1 = textArray1.Length;
            if ((num1 < 1) || (num1 > 4))
            {
                throw new ArgumentException("Arg_VersionString");
            }

            major = int.Parse(textArray1[0], CultureInfo.InvariantCulture);
            if (major < 0)
            {
                throw new ArgumentOutOfRangeException("version", "ArgumentOutOfRange_Version");
            }
            if (num1 == 1) return;

            minor = int.Parse(textArray1[1], CultureInfo.InvariantCulture);
            if (minor < 0)
            {
                throw new ArgumentOutOfRangeException("version", "ArgumentOutOfRange_Version");
            }
            num1 -= 2;
            if (num1 > 0)
            {
                build = int.Parse(textArray1[2], CultureInfo.InvariantCulture);
                if (build < 0)
                {
                    throw new ArgumentOutOfRangeException("build", "ArgumentOutOfRange_Version");
                }
                num1--;
                if (num1 > 0)
                {
                    revision = int.Parse(textArray1[3], CultureInfo.InvariantCulture);
                    if (revision < 0)
                    {
                        throw new ArgumentOutOfRangeException("revision", "ArgumentOutOfRange_Version");
                    }
                }
            }
        }
        /// <summary>
        /// Creates a new <see cref="Version"/> instance.
        /// </summary>
        /// <param name="major">Major.</param>
        /// <param name="minor">Minor.</param>
        public Version(int major, int minor)
        {
            build = -1;
            revision = -1;
            if (major < 0)
            {
                throw new ArgumentOutOfRangeException("major", "ArgumentOutOfRange_Version");
            }
            if (minor < 0)
            {
                throw new ArgumentOutOfRangeException("minor", "ArgumentOutOfRange_Version");
            }
            this.major = major;
            this.minor = minor;
            this.major = major;
        }
        /// <summary>
        /// Creates a new <see cref="Version"/> instance.
        /// </summary>
        /// <param name="major">Major.</param>
        /// <param name="minor">Minor.</param>
        /// <param name="build">Build.</param>
        public Version(int major, int minor, int build)
        {
            this.build = -1;
            this.revision = -1;
            if (major < 0)
            {
                throw new ArgumentOutOfRangeException("major", "ArgumentOutOfRange_Version");
            }
            if (minor < 0)
            {
                throw new ArgumentOutOfRangeException("minor", "ArgumentOutOfRange_Version");
            }
            if (build < 0)
            {
                throw new ArgumentOutOfRangeException("build", "ArgumentOutOfRange_Version");
            }
            this.major = major;
            this.minor = minor;
            this.build = build;
        }
        /// <summary>
        /// Creates a new <see cref="Version"/> instance.
        /// </summary>
        /// <param name="major">Major.</param>
        /// <param name="minor">Minor.</param>
        /// <param name="build">Build.</param>
        /// <param name="revision">Revision.</param>
        public Version(int major, int minor, int build, int revision)
        {
            this.build = -1;
            this.revision = -1;
            if (major < 0)
            {
                throw new ArgumentOutOfRangeException("major", "ArgumentOutOfRange_Version");
            }
            if (minor < 0)
            {
                throw new ArgumentOutOfRangeException("minor", "ArgumentOutOfRange_Version");
            }
            if (build < 0)
            {
                throw new ArgumentOutOfRangeException("build", "ArgumentOutOfRange_Version");
            }
            if (revision < 0)
            {
                throw new ArgumentOutOfRangeException("revision", "ArgumentOutOfRange_Version");
            }
            this.major = major;
            this.minor = minor;
            this.build = build;
            this.revision = revision;
        }
        #region ICloneable Members
        /// <summary>
        /// Clones this instance.
        /// </summary>
        /// <returns></returns>
        public object Clone()
        {
            Version version1 = new Version();
            version1.major = major;
            version1.minor = minor;
            version1.build = build;
            version1.revision = revision;
            return version1;
        }

        public static bool TryParse(string input, ref Version result)
        {
            try
            {
                result = new Version(input);
                return true;
            }
            catch
            {
                return false;
            }
        }

        public Version Parse(string input)
        {
            return new Version(input);
        }

        #endregion
        #region IComparable Members
        /// <summary>
        /// Compares to.
        /// </summary>
        /// <param name="obj">Obj.</param>
        /// <returns></returns>
        public int CompareTo(object obj)
        {
            var version = TryConvertIntoVersion(obj);
            if (version == null)
                throw new ArgumentException("Argument must be a version");

            if (major != version.Major)
            {
                if (major > version.Major)
                {
                    return 1;
                }
                return -1;
            }
            if (minor != version.Minor)
            {
                if (minor > version.Minor)
                {
                    return 1;
                }
                return -1;
            }
            if (build != version.Build)
            {
                if (build > version.Build)
                {
                    return 1;
                }
                return -1;
            }
            if (revision == version.Revision)
            {
                return 0;
            }
            if (revision > version.Revision)
            {
                return 1;
            }
            return -1;
        }
        #endregion

        /// <summary>
        /// Equalss the specified obj.
        /// </summary>
        /// <param name="obj">Obj.</param>
        /// <returns></returns>
        public override bool Equals(object obj)
        {
            var version = TryConvertIntoVersion(obj);

            if (obj == null)
                return false;

            if (((major == version.Major) && (minor == version.Minor)) && (build == version.Build) && (revision == version.Revision))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        /// <summary>
        /// Gets the hash code.
        /// </summary>
        /// <returns></returns>
        public override int GetHashCode()
        {
            int num1 = 0;
            num1 |= ((major & 15) << 0x1c);
            num1 |= ((minor & 0xff) << 20);
            num1 |= ((build & 0xff) << 12);
            return (num1 | revision & 0xfff);
        }

        /// <summary>
        /// Operator ==s the specified v1.
        /// </summary>
        /// <param name="v1">V1.</param>
        /// <param name="v2">V2.</param>
        /// <returns></returns>
        public static bool operator ==(Version v1, Version v2)
        {
            if (ReferenceEquals(v1, null)) return ReferenceEquals(v2, null);
            if (ReferenceEquals(v1, null)) return false;

            return v1.Equals(v2);
        }

        /// <summary>
        /// Operator !=s the specified v1.
        /// </summary>
        /// <param name="v1">V1.</param>
        /// <param name="v2">V2.</param>
        /// <returns></returns>
        public static bool operator !=(Version v1, Version v2)
        {
            if (ReferenceEquals(v1, null)) return !ReferenceEquals(v2, null);
            if (ReferenceEquals(v1, null)) return true;

            return !v1.Equals(v2);
        }

        /// <summary>
        /// Operator &gt;s the specified v1.
        /// </summary>
        /// <param name="v1">V1.</param>
        /// <param name="v2">V2.</param>
        /// <returns></returns>
        public static bool operator >(Version v1, Version v2)
        {
            return (v1.CompareTo(v2) > 0);
        }

        /// <summary>
        /// Operator &lt;s the specified v1.
        /// </summary>
        /// <param name="v1">V1.</param>
        /// <param name="v2">V2.</param>
        /// <returns></returns>
        public static bool operator <(Version v1, Version v2)
        {
            return (v1.CompareTo(v2) < 0);
        }

        /// <summary>
        /// Operator &lt;=s the specified v1.
        /// </summary>
        /// <param name="v1">V1.</param>
        /// <param name="v2">V2.</param>
        /// <returns></returns>
        public static bool operator >=(Version v1, Version v2)
        {
            return (v1.CompareTo(v2) >= 0);
        }

        /// <summary>
        /// Operator &gt;=s the specified v1.
        /// </summary>
        /// <param name="v1">V1.</param>
        /// <param name="v2">V2.</param>
        /// <returns></returns>
        public static bool operator <=(Version v1, Version v2)
        {
            return (v1.CompareTo(v2) <= 0);
        }


        public static implicit operator System.Version(AutomatedLab.Version version)
        {
            return new System.Version(version.Major, version.Minor, version.Build, version.Revision);
        }

        public static implicit operator AutomatedLab.Version(System.Version version)
        {
            if (version.Revision != -1)
                return new AutomatedLab.Version(version.Major, version.Minor, version.Build, version.Revision);
            else if (version.Build != -1)
                return new AutomatedLab.Version(version.Major, version.Minor, version.Build);
            else
                return new AutomatedLab.Version(version.Major, version.Minor);
        }

        public static implicit operator AutomatedLab.Version(string version)
        {
            return new AutomatedLab.Version(version);
        }

        public static implicit operator string (AutomatedLab.Version version)
        {
            return version.ToString();
        }

        /// <summary>
        /// Toes the string.
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            if (build == -1)
            {
                return ToString(2);
            }
            if (revision == -1)
            {
                return ToString(3);
            }
            return ToString(4);
        }
        /// <summary>
        /// Toes the string.
        /// </summary>
        /// <param name="fieldCount">Field count.</param>
        /// <returns></returns>
        public string ToString(int fieldCount)
        {
            object[] objArray1;
            switch (fieldCount)
            {
                case 0:
                    {
                        return string.Empty;
                    }
                case 1:
                    {
                        return (major.ToString());
                    }
                case 2:
                    {
                        return (major.ToString() + "." + minor.ToString());
                    }
            }
            if (build == -1)
            {
                throw new ArgumentException(string.Format("ArgumentOutOfRange_Bounds_Lower_Upper {0},{1}", "0", "2"), "fieldCount");
            }
            if (fieldCount == 3)
            {
                objArray1 = new object[5] { major, ".", minor, ".", build };
                return string.Concat(objArray1);
            }
            if (revision == -1)
            {
                throw new ArgumentException(string.Format("ArgumentOutOfRange_Bounds_Lower_Upper {0},{1}", "0", "3"), "fieldCount");
            }
            if (fieldCount == 4)
            {
                objArray1 = new object[7] { major, ".", minor, ".", build, ".", revision };
                return string.Concat(objArray1);
            }
            throw new ArgumentException(string.Format("ArgumentOutOfRange_Bounds_Lower_Upper {0},{1}", "0", "4"), "fieldCount");
        }

        private Version TryConvertIntoVersion(object obj)
        {
            Version version = null;

            if (obj == null)
                return version;

            try
            {
                version = obj as AutomatedLab.Version;
                if (version != null)
                    return version;
            }
            catch { }

            try
            {
                version = (AutomatedLab.Version)(System.Version)obj;
                if (version != null)
                    return version;
            }
            catch { }

            try
            {
                version = obj as string;
                if (version != null)
                    return version;
            }
            catch { }

            return version;
        }
    }
}