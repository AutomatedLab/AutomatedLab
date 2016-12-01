using System;
using System.Collections;
using System.IO;
using System.Text;
using System.Xml.Serialization;

namespace AutomatedLab
{
    [Serializable]
    public class DictionaryXmlStore<TKey, TValue> : SerializableDictionary<TKey, TValue>
    {
        public DictionaryXmlStore()
        { }

        public DictionaryXmlStore(Hashtable hashtable)
        {
            foreach (DictionaryEntry kvp in hashtable)
            {
                Add((TKey)kvp.Key, (TValue)kvp.Value);
            }
        }

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

        public string ExportToString()
        {
            var serializer = new XmlSerializer(typeof(DictionaryXmlStore<TKey, TValue>));
            var sb = new StringBuilder();
            var sw = new StringWriter(sb);

            serializer.Serialize(sw, this);

            sw.Close();

            return sb.ToString();
        }

        public static DictionaryXmlStore<TKey, TValue> ImportFromString(string s)
        {
            var serializer = new XmlSerializer(typeof(DictionaryXmlStore<TKey, TValue>));
            var sr = new StringReader(s);

            var items = (DictionaryXmlStore<TKey, TValue>)serializer.Deserialize(sr);

            sr.Close();

            return items;
        }

        public static DictionaryXmlStore<TKey, TValue> ImportFromRegistry(string keyName, string valueName)
        {
            var serializer = new XmlSerializer(typeof(DictionaryXmlStore<TKey, TValue>));

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
