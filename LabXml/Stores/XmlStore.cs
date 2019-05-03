using System;
using System.IO;
using System.Xml.Serialization;
using Microsoft.Win32;

namespace AutomatedLab
{
    [Serializable]
    public class XmlStore<T> : ICloneable where T : class
    {
        public void ExportToRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(XmlStore<T>));
            var xmlNamespace = new XmlSerializerNamespaces();
            xmlNamespace.Add(string.Empty, string.Empty);

            var sw = new StringWriter();

            //makes sure the key exists and does nothing if does already exist
            var assemblyName = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            var registryPath = string.Format(@"SOFTWARE\{0}\{1}", assemblyName, keyName);
            var key = Registry.CurrentUser.CreateSubKey(registryPath);

            serializer.Serialize(sw, this, xmlNamespace);

            key.SetValue(valueName, sw.ToString(), RegistryValueKind.String);
            key.Close();
        }

        public byte[] Export()
        {
            var serializer = new XmlSerializer(typeof(T));
            var xmlNamespace = new XmlSerializerNamespaces();
            xmlNamespace.Add(string.Empty, string.Empty);
            var stream = new MemoryStream();

            serializer.Serialize(stream, this, xmlNamespace);

            stream.Close();

            return stream.ToArray();
        }

        public void Export(string path)
        {
            File.Delete(path);

            var serializer = new XmlSerializer(typeof(T));
            var xmlNamespace = new XmlSerializerNamespaces();
            xmlNamespace.Add(string.Empty, string.Empty);
            var fileStream = new FileStream(path, FileMode.CreateNew);

            serializer.Serialize(fileStream, this, xmlNamespace);

            fileStream.Close();
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

        public static T Import(byte[] data)
        {
            var serializer = new XmlSerializer(typeof(T));
            var stream = new MemoryStream(data);

            var items = (T)serializer.Deserialize(stream);

            stream.Close();

            return items;
        }

        public static XmlStore<T> ImportFromRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(XmlStore<T>));

            //makes sure the key exists and does nothing if does already exist
            var assemblyName = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            var registryPath = string.Format(@"SOFTWARE\{0}\{1}", assemblyName, keyName);
            var key = Registry.CurrentUser.OpenSubKey(registryPath);

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
