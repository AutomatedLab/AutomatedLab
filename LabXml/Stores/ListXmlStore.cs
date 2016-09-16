using System;
using System.IO;
using System.Text;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class ListXmlStore<T> : SerializableList<T>
    {
        public byte[] Export()
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));

            var stream = new MemoryStream();

            serializer.Serialize(stream, this);

            stream.Close();

            return stream.ToArray();
        }

        public static ListXmlStore<T> Import(byte[] data)
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));
            var stream = new MemoryStream(data);

            var items = (ListXmlStore<T>)serializer.Deserialize(stream);

            stream.Close();

            return items;
        }

        public void AddFromFile(string path)
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));
            var fileStream = new FileStream(path, FileMode.Open);

            AddRange((ListXmlStore<T>)serializer.Deserialize(fileStream));

            fileStream.Close();
        }

        public static ListXmlStore<T> Import(string path)
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));
            FileStream fileStream = new FileStream(path, FileMode.Open);

            var items = (ListXmlStore<T>)serializer.Deserialize(fileStream);

            fileStream.Close();

            return items;
        }

        public void Export(string path)
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));
            var fileStream = new FileStream(path, FileMode.OpenOrCreate);

            serializer.Serialize(fileStream, this);

            fileStream.Close();
        }

        public static ListXmlStore<T> ImportFromRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));

            //makes sure the key exists and does nothing if does already exist
            var assemblyName = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            var registryPath = string.Format(@"SOFTWARE\{0}\{1}", assemblyName, keyName);
            var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(registryPath);

            var sr = new StringReader(key.GetValue(valueName).ToString());

            var items = (ListXmlStore<T>)serializer.Deserialize(sr);

            sr.Close();

            return items;
        }

        public void ExportToRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));
            var sw = new StringWriter();

            //makes sure the key exists and does nothing if does already exist
            var assemblyName = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            var registryPath = string.Format(@"SOFTWARE\{0}\{1}", assemblyName, keyName);
            var key = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(registryPath);

            serializer.Serialize(sw, this);

            key.SetValue(valueName, sw.ToString(), Microsoft.Win32.RegistryValueKind.String);
            key.Close();
        }
        public string ExportToString()
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));
            var sb = new StringBuilder();
            var sw = new StringWriter();

            serializer.Serialize(sw, this);

            sw.Close();

            return sb.ToString();
        }

        public static ListXmlStore<T> ImportFromString(string s)
        {
            var serializer = new XmlSerializer(typeof(ListXmlStore<T>));
            var sr = new StringReader(s);

            var items = (ListXmlStore<T>)serializer.Deserialize(sr);

            sr.Close();

            return items;
        }
    }
}
