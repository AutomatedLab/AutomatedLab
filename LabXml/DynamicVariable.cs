using System;
using System.Collections.ObjectModel;
using System.Management.Automation;

namespace AutomatedLab
{
    public class DynamicVariable : PSVariable
    {
        public DynamicVariable(
            string name,
            ScriptBlock scriptGetter,
            ScriptBlock scriptSetter)
                : base(name, null, ScopedItemOptions.AllScope)
        {
            getter = scriptGetter;
            setter = scriptSetter;
            Visibility = SessionStateEntryVisibility.Public;
        }
        private ScriptBlock getter;
        private ScriptBlock setter;

        public override object Value
        {
            get
            {
                if (getter != null)
                {
                    Collection<PSObject> results = getter.Invoke();
                    if (results.Count == 1)
                    {
                        return results[0];
                    }
                    else
                    {
                        PSObject[] returnResults =
                            new PSObject[results.Count];
                        results.CopyTo(returnResults, 0);
                        return returnResults;
                    }
                }
                else { return null; }
            }
            set
            {
                if (setter != null) { setter.Invoke(value); }
            }
        }
    }
}
