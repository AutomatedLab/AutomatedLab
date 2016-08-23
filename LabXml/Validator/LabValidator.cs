using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;

namespace AutomatedLab
{
    public class LabValidator : ValidatorBase, IValidate
    {
        private List<XmlDocument> docs = new List<XmlDocument>();
        protected Lab lab;
        protected ListXmlStore<Machine> machines = new ListXmlStore<Machine>();

        public LabValidator(string labXmlPath)
        {
            XmlDocument mainDoc = new XmlDocument();
            mainDoc.Load(labXmlPath);
            docs.Add(mainDoc);

            var xmlPaths = mainDoc.SelectNodes("//@Path").OfType<XmlAttribute>().Select(e => e.Value).Where(text => text.EndsWith(".xml"));

            foreach (var path in xmlPaths)
            {
                XmlDocument doc = new XmlDocument();
                doc.Load(path);
                docs.Add(doc);
            }

            lab = Lab.Import(labXmlPath);
            lab.MachineDefinitionFiles.ForEach(file => machines.AddFromFile(file.Path));
            lab.Machines = machines;
        }

        public LabValidator() :
            this(XmlValidatorArgs.XmlPath)
        { }
    }

    public static class LabValidatorArgs
    {
        public static string XmlPath { get; set; }
    }

}
