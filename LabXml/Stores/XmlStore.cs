using System;
using System.IO;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class XmlStore<T> : ICloneable where T : class
    {
        public static T Import(byte[] data)
        {
            var serializer = new XmlSerializer(typeof(T));
            var stream = new MemoryStream(data);

            var items = (T)serializer.Deserialize(stream);

            stream.Close();

            return items;
        }

        public byte[] Export()
        {
            var serializer = new XmlSerializer(typeof(T));
            var stream = new MemoryStream();

            serializer.Serialize(stream, this);

            stream.Close();

            return stream.ToArray();
        }

        public static T Import(string path)
        {
            var serializer = new XmlSerializer(typeof(T));
            T item = null;

            var fileStream = new FileStream(path, FileMode.Open);

            item = (T)serializer.Deserialize(fileStream);

            fileStream.Close();

            return item;
        }

        public void Export(string path)
        {
            var serializer = new XmlSerializer(typeof(T));
            var fileStream = new FileStream(path, FileMode.OpenOrCreate);

            serializer.Serialize(fileStream, this);

            fileStream.Close();
        }

        public static XmlStore<T> ImportFromRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(XmlStore<T>));

            //makes sure the key exists and does nothing if does already exist
            var assemblyName = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            var registryPath = string.Format(@"SOFTWARE\{0}\{1}", assemblyName, keyName);
            var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(registryPath);

            if (key == null)
                throw new FileNotFoundException(string.Format("The registry key '{0}' does not exist", registryPath));

            var value = key.GetValue(valueName);

            if (value == null)
                throw new FileNotFoundException(string.Format("The registry value '{0}' does not exist in key '{1}'", valueName, registryPath));

            StringReader sr = new StringReader(value.ToString());

            var item = (XmlStore<T>)serializer.Deserialize(sr);

            sr.Close();

            return item;
        }

        public void ExportToRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(XmlStore<T>));
            var sw = new StringWriter();

            //makes sure the key exists and does nothing if does already exist
            var assemblyName = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            var registryPath = string.Format(@"SOFTWARE\{0}\{1}", assemblyName, keyName);
            var key = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(registryPath);

            serializer.Serialize(sw, this);

            key.SetValue(valueName, sw.ToString(), Microsoft.Win32.RegistryValueKind.String);
            key.Close();
        }

        public object Clone()
        {
            var serializer = new XmlSerializer(typeof(T));
            var stream = new MemoryStream();

            serializer.Serialize(stream, this);

            var item = (T)serializer.Deserialize(stream);

            return item;
        }
    }
}