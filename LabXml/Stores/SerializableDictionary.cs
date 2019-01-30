using System;
using System.Collections;
using System.Collections.Generic;
using System.Xml.Serialization;
using System.Linq;

namespace AutomatedLab
{
    [XmlRoot("dictionary")]
    public class SerializableDictionary<TKey, TValue>
        : Dictionary<TKey, TValue>, IXmlSerializable
    {
        List<string> builtinProperties = new List<string>() { "Capacity", "Item" };

        public DateTime Timestamp { get; set; }
        public Guid ID { get; set; }
        public List<string> Metadata { get; set; }

        public SerializableDictionary()
            : base()
        {
            Metadata = new List<string>();
        }

        public SerializableDictionary(IDictionary<TKey, TValue> dictionary)
            : base(dictionary)
        {
        }

        #region IXmlSerializable Members
        public System.Xml.Schema.XmlSchema GetSchema()
        {
            return null;
        }

        public void ReadXml(System.Xml.XmlReader reader)
        {
            XmlSerializer keySerializer = new XmlSerializer(typeof(TKey));
            XmlSerializer valueSerializer = new XmlSerializer(typeof(TValue));

            var propertyInfos = GetType().GetProperties().Where(pi => !builtinProperties.Contains(pi.Name));

            bool wasEmpty = reader.IsEmptyElement;
            reader.Read();

            if (wasEmpty)
                return;

            while (reader.NodeType != System.Xml.XmlNodeType.EndElement)
            {
                var propertyInfo = propertyInfos.Where(pi => pi.Name == reader.Name).FirstOrDefault();
                if (propertyInfo != null)
                {
                    reader.ReadStartElement();

                    var serializer = new XmlSerializer(propertyInfo.PropertyType);
                    propertyInfo.SetValue(this, serializer.Deserialize(reader));

                    reader.ReadEndElement();
                }
                else
                {
                    reader.ReadStartElement("item");

                    reader.ReadStartElement("key");
                    TKey key = (TKey)keySerializer.Deserialize(reader);
                    reader.ReadEndElement();

                    reader.ReadStartElement("value");
                    TValue value = (TValue)valueSerializer.Deserialize(reader);
                    reader.ReadEndElement();

                    Add(key, value);

                    reader.ReadEndElement();
                    reader.MoveToContent();
                }
            }
            reader.ReadEndElement();
        }

        public void WriteXml(System.Xml.XmlWriter writer)
        {
            XmlSerializer keySerializer = new XmlSerializer(typeof(TKey));
            XmlSerializer valueSerializer = new XmlSerializer(typeof(TValue));
            var xmlNamespace = new XmlSerializerNamespaces();
            xmlNamespace.Add(string.Empty, string.Empty);

            var propertyInfos = GetType().GetProperties()
                .Where(pi => pi.CanWrite && !builtinProperties.Contains(pi.Name)).ToList();
            foreach (var propertyInfo in propertyInfos)
            {
                var serializer = new XmlSerializer(propertyInfo.PropertyType);
                writer.WriteStartElement(propertyInfo.Name);
                serializer.Serialize(writer, propertyInfo.GetValue(this), xmlNamespace);
                writer.WriteEndElement();
            }

            foreach (TKey key in Keys)
            {
                writer.WriteStartElement("item");

                writer.WriteStartElement("key");
                keySerializer.Serialize(writer, key, xmlNamespace);
                writer.WriteEndElement();

                writer.WriteStartElement("value");
                TValue value = this[key];
                valueSerializer.Serialize(writer, value, xmlNamespace);
                writer.WriteEndElement();

                writer.WriteEndElement();
            }
        }
        #endregion

        #region Operators
        public static implicit operator SerializableDictionary<TKey, TValue>(Hashtable hashtable)
        {
            var serializableDictionary = new SerializableDictionary<TKey, TValue>();

            foreach (DictionaryEntry item in hashtable)
            {
                try
                {
                    serializableDictionary.Add((TKey)item.Key, (TValue)item.Value);
                }
                catch (Exception ex)
                {
                    throw new ArgumentException(string.Format("The entry with the key '{0}' could not be added due to the error: {1}", item.Key, ex.Message), ex);
                }
            }

            return serializableDictionary;
        }

        public static implicit operator Hashtable(SerializableDictionary<TKey, TValue> serializableDictionary)
        {
            var hashtable = new Hashtable();

            foreach (var item in serializableDictionary)
            {
                hashtable.Add(item.Key, item.Value);
            }

            return hashtable;
        }
        #endregion
    }
}
