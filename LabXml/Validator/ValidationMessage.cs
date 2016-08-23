using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Reflection;

namespace AutomatedLab
{
    public class ValidationMessage
    {
        public MessageType Type { get; set; }
        public string Message { get; set; }
        public string ValueName { get; set; }
        public string TargetObject { get; set; }
        public string HelpText { get; set; }
        public string ValidatorName { get; set; }

        public ValidationMessage()
        {
            try
            {
                ValidatorName = new StackTrace().GetFrame(5).GetMethod().DeclaringType.Name;
            }
            catch
            {
                ValidatorName = "unknown";
            }
        }

        public override string ToString()
        {
            return string.Format("{0}: {1}, Target Object {2} from value {3} ", Type, Message, TargetObject, ValueName);
        }
    }

    public class ValidationMessageContainer
    {
        private string validatorName;
        private List<ValidationMessage> messages;
        private TimeSpan runtime;
        private bool pass;

        public string ValidatorName
        {
            get { return validatorName; }
            set { validatorName = value; }
        }

        public List<ValidationMessage> Messages
        {
            get { return messages; }
            set { messages = value; }
        }

        public TimeSpan Runtime
        {
            get { return runtime; }
            set { runtime = value; }
        }

        public bool Pass
        {
            get
            {
                if (messages.Where(m => m.Type == MessageType.Error).Count() > 0)
                    return false;
                else
                    return true;
            }
        }

        public ValidationMessageContainer()
        {
            messages = new List<ValidationMessage>();
        }

        public ValidationMessageContainer(string validatorName, TimeSpan runtime, IEnumerable<ValidationMessage> messages)
        {
            this.validatorName = validatorName;
            this.messages = messages.ToList();
            this.runtime = runtime;
        }

        public override string ToString()
        {
            return string.Format("{0} ({1} Messages)", validatorName, messages.ToString());
        }

        public void AddSummary()
        {
            pass = true;

            if (messages.Where(m => m.Type == MessageType.Error).Count() > 0)
            {
                messages.Add(new ValidationMessage
                {
                    Message = "Error",
                    Type = MessageType.Summary,
                    TargetObject = "Lab",
                    ValidatorName = MethodBase.GetCurrentMethod().Name
                });

                pass = false;
            }
            else if (messages.Where(m => m.Type == MessageType.Warning).Count() > 0)
            {
                messages.Add(new ValidationMessage
                {
                    Message = "Warning",
                    Type = MessageType.Summary,
                    TargetObject = "Lab",
                    ValidatorName = MethodBase.GetCurrentMethod().Name
                });
            }
            else
            {
                messages.Add(new ValidationMessage
                {
                    Message = "Ok",
                    Type = MessageType.Summary,
                    TargetObject = "Lab",
                    ValidatorName = MethodBase.GetCurrentMethod().Name
                });
            }
        }

        public IEnumerable<ValidationMessage> GetFilteredMessages(MessageType filter = MessageType.Default)
        {
            return messages.Where(m => (m.Type & filter) == m.Type);
        }

        public static ValidationMessageContainer operator +(ValidationMessageContainer source, ValidationMessageContainer destination)
        {
            destination.messages.AddRange(source.messages);
            destination.runtime += source.runtime;

            return destination;
        }
    }

    [Flags]
    public enum MessageType
    {
        Debug = 1,
        Verbose = 2,
        Information = 4,
        Warning = 8,
        Error = 16,
        Summary = 32,
        All = Debug | Verbose | Information | Warning | Error | Summary,
        Default = Information | Warning | Error | Summary,
        VerboseDebug = Verbose | Debug
    }
}
