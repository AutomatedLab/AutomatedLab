using System;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class Path
    {
        [XmlAttribute("Path")]
        public string Value { get; set; }

        public static implicit operator String(Path path)
        {
            return path.Value;
        }

        public static implicit operator Path(string path)
        {
            return new Path() { Value = path };
        }

        public override string ToString()
        {
            return Value;
        }

        public override bool Equals(object obj)
        {
            var path = obj as Path;

            if (path == null)
                return false;

            return Value == path.Value;
        }

        public override int GetHashCode()
        {
            return Value.GetHashCode();
        }
    } 
}
