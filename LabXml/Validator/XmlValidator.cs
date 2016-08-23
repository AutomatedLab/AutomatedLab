using System.Collections.Generic;
using System.Linq;
using System.Xml;

namespace AutomatedLab
{
    public class XmlValidator : ValidatorBase
    {
        protected List<XmlDocument> docs = new List<XmlDocument>();

        public XmlValidator(string xmlPath, bool loadAdditionalXmlFiles = true)
        {
            XmlDocument mainDoc = new XmlDocument();
            mainDoc.Load(xmlPath);
            docs.Add(mainDoc);

            var xmlPaths = mainDoc.SelectNodes("//@Path").OfType<XmlAttribute>().Select(e => e.Value).Where(text => text.EndsWith(".xml"));

            foreach (var path in xmlPaths)
            {
                XmlDocument doc = new XmlDocument();
                doc.Load(path);
                docs.Add(doc);
            }
        }

        public XmlValidator() :
            this(XmlValidatorArgs.XmlPath, XmlValidatorArgs.LoadAdditionalFiles)
        { }
    }

    public static class XmlValidatorArgs
    {
        public static string XmlPath { get; set; }
        public static bool LoadAdditionalFiles { get; set; }
    }

}
