using AutomatedLab;
using LabXml;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab
{
    public class ValidatorBase : IValidate
    {
        protected ValidationMessageContainer messageContainer;
        protected static Hashtable validationSettings;


        public ValidationMessageContainer MessageContainer
        {
            get { return messageContainer; }
            set { messageContainer = value; }
        }

        public static Hashtable ValidationSettings
        {
            get { return validationSettings; }
            set { validationSettings = value; }
        }

        public TimeSpan Runtime
        {
            get { return messageContainer.Runtime; }
        }

        public ValidatorBase()
        {
            messageContainer = new ValidationMessageContainer();

            if (validationSettings == null)
            {
                PowerShellHelper.InvokeCommand("Import-Module -Name AutomatedLab");
                validationSettings = (Hashtable)PowerShellHelper.InvokeCommand("[hashtable](Get-LabConfigurationItem -Name ValidationSettings)").FirstOrDefault().BaseObject;
            }
        }

        public ValidationMessageContainer RunValidation()
        {
            var start = DateTime.Now;
            System.Threading.Thread.Sleep(10);

            var container = new ValidationMessageContainer();
            container.Messages = Validate().ToList();
            container.ValidatorName = new System.Diagnostics.StackTrace().GetFrame(1).GetMethod().DeclaringType.Name;

            var end = DateTime.Now;
            container.Runtime = end - start;

            return container;
        }

        public virtual IEnumerable<ValidationMessage> Validate()
        {
            return new List<ValidationMessage>() { new ValidationMessage() { Message = "Dummy" } };
        }
    }
}

public interface IValidate
{
    IEnumerable<ValidationMessage> Validate();

    ValidationMessageContainer MessageContainer { get; }
}
