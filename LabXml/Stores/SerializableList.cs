using System;
using System.Collections.Generic;
using System.Xml.Serialization;
using System.Linq;

namespace AutomatedLab
{
    [XmlRoot("list")]
    public class SerializableList<T>
        : List<T>, IXmlSerializable
    {
        List<string> builtinProperties = new List<string>() { "Capacity", "Item" };

        public DateTime Timestamp { get; set; }
        public Guid ID { get; set; }
        public List<string> Metadata { get; set; }

        public SerializableList()
            : base()
        {
            Metadata = new List<string>();
        }

        #region IXmlSerializable Members
        public System.Xml.Schema.XmlSchema GetSchema()
        {
            return null;
        }

        public void ReadXml(System.Xml.XmlReader reader)
        {
            XmlSerializer itemSerializer = new XmlSerializer(typeof(T));

            var propertyInfos = this.GetType().GetProperties().Where(pi => !builtinProperties.Contains(pi.Name));

            bool wasEmpty = reader.IsEmptyElement;
            reader.Read();

            if (wasEmpty)
                return;

            while (!reader.EOF)
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
                    T item = (T)itemSerializer.Deserialize(reader);
                    this.Add(item);

                    if (reader.NodeType == System.Xml.XmlNodeType.EndElement)
                        reader.ReadEndElement();

                    reader.MoveToContent();
                }
            }
        }

        public void WriteXml(System.Xml.XmlWriter writer)
        {
            XmlSerializer itemSerializer = new XmlSerializer(typeof(T));

            var propertyInfos = this.GetType().GetProperties()
                .Where(pi => pi.CanWrite && !builtinProperties.Contains(pi.Name)).ToList();
            foreach (var propertyInfo in propertyInfos)
            {
                var serializer = new XmlSerializer(propertyInfo.PropertyType);
                writer.WriteStartElement(propertyInfo.Name);
                serializer.Serialize(writer, propertyInfo.GetValue(this));
                writer.WriteEndElement();
            }

            foreach (T item in this)
            {
                itemSerializer.Serialize(writer, item);
            }
        }
        #endregion
    }
}