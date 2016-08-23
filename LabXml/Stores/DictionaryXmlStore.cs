using System;
using System.IO;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class DictionaryXmlStore<TKey, TValue> : SerializableDictionary<TKey, TValue>
    {
        public void AddFromFile(string path)
        {
            var serializer = new XmlSerializer(typeof(DictionaryXmlStore<TKey, TValue>));
            FileStream fileStream = new FileStream(path, FileMode.Open);

            var newItems = (DictionaryXmlStore<TKey, TValue>)serializer.Deserialize(fileStream);
            newItems.ForEach(item => Add(item.Key, item.Value));
            
            fileStream.Close();
        }

        public static DictionaryXmlStore<TKey, TValue> Import(string path)
        {
            var serializer = new XmlSerializer(typeof(DictionaryXmlStore<TKey, TValue>));
            FileStream fileStream = new FileStream(path, FileMode.Open);

            var items = (DictionaryXmlStore<TKey, TValue>)serializer.Deserialize(fileStream);

            fileStream.Close();

            return items;
        }

        public void Export(string path)
        {
            var serializer = new XmlSerializer(typeof(DictionaryXmlStore<TKey, TValue>));
            FileStream fileStream = new FileStream(path, FileMode.OpenOrCreate);

            serializer.Serialize(fileStream, this);

            fileStream.Close();
        }

        public static DictionaryXmlStore<TKey, TValue> ImportFromRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(DictionaryXmlStore<TKey, TValue>));

            //makes sure the key exists and does nothing if does already exist
            var assemblyName = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            var registryPath = string.Format(@"SOFTWARE\{0}\{1}", assemblyName, keyName);
            var key = Microsoft.Win32.Registry.CurrentUser.OpenSubKey(registryPath);

            StringReader sr = new StringReader(key.GetValue(valueName).ToString());

            var items = (DictionaryXmlStore<TKey, TValue>)serializer.Deserialize(sr);

            sr.Close();

            return items;
        }

        public void ExportToRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(DictionaryXmlStore<TKey, TValue>));
            StringWriter sw = new StringWriter();

            //makes sure the key exists and does nothing if does already exist
            var assemblyName = System.Reflection.Assembly.GetExecutingAssembly().GetName().Name;
            var registryPath = string.Format(@"SOFTWARE\{0}\{1}", assemblyName, keyName);
            var key = Microsoft.Win32.Registry.CurrentUser.CreateSubKey(registryPath);

            serializer.Serialize(sw, this);

            key.SetValue(valueName, sw.ToString(), Microsoft.Win32.RegistryValueKind.String);
            key.Close();
        }
    }
}
