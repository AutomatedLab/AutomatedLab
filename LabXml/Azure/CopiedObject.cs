using System;
using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class CopiedObject<T>
    {
        private List<string> nonMappedProperties;

        public List<string> NonMappedProperties
        {
            get { return nonMappedProperties; }
        }

        public CopiedObject()
        {
            nonMappedProperties = new List<string>();
        }

        protected static T Create<T>(object input) where T : CopiedObject<T>, new()
        {
            T to = new T();

            if (typeof(System.Management.Automation.PSObject) == input.GetType())
            {
                input = input.GetType().GetProperty("BaseObject").GetValue(input);
            }

            var toProperties = to.GetType().GetProperties().Where(p => p.CanWrite).ToList();
            var fromProperties = input.GetType().GetProperties();

            foreach (var toProperty in toProperties)
            {
                //get the property with the same name, the same generic argument count
                var fromProperty = fromProperties.Where(p => p.Name == toProperty.Name &&
                    p.PropertyType.GenericTypeArguments.Count() == toProperty.PropertyType.GenericTypeArguments.Count()).FirstOrDefault();

                if (fromProperty != null)
                {
                    //if the type of the fromProperty is a Dictionary of the same type than the SerializableDictionary of the toProperty
                    if (fromProperty.PropertyType.IsGenericType && typeof(IDictionary<,>) == fromProperty.PropertyType.GetGenericTypeDefinition() && typeof(IDictionary<,>).MakeGenericType(toProperty.PropertyType.GetGenericArguments()) == fromProperty.PropertyType)
                    {
                        var t = typeof(SerializableDictionary<,>).MakeGenericType(toProperty.PropertyType.GetGenericArguments());
                        var value = fromProperty.GetValue(input);
                        object o = value == null ? Activator.CreateInstance(t) : Activator.CreateInstance(t, value);
                        toProperty.SetValue(to, o);
                    }
                    else if (fromProperty.PropertyType.IsInterface || fromProperty.PropertyType == toProperty.PropertyType || toProperty.PropertyType == typeof(string))
                    {
                        //if the target property type is string and the source not, ToString is used to convert the object into a string if the property value if not null
                        if (toProperty.PropertyType == typeof(string) & fromProperty.PropertyType != typeof(string) & fromProperty.GetValue(input) != null)
                            toProperty.SetValue(to, fromProperty.GetValue(input).ToString());
                        else
                            toProperty.SetValue(to, fromProperty.GetValue(input));
                    }
                    //if the properties do not match any of the previous conditions, check if the target property is derived from CopiedObject<>
                    else if (toProperty.PropertyType.BaseType.IsGenericType && toProperty.PropertyType.BaseType.GetGenericTypeDefinition() == typeof(CopiedObject<>))
                    {
                        //get the source value
                        var value = fromProperty.GetValue(input);

                        //and the generic type according to the target property
                        var t = typeof(CopiedObject<>).MakeGenericType(toProperty.PropertyType);

                        //retrieve the static method "Create" and create a new object
                        var createMethodInfo = t.GetMethod("Create", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic).MakeGenericMethod(new[] { toProperty.PropertyType });
                        var @object = createMethodInfo.Invoke(null, new[] { value });

                        //if the object is not null, set the target property with it
                        if (@object != null)
                            toProperty.SetValue(to, @object);
                    }
                    else if (toProperty.PropertyType.IsArray && fromProperty.PropertyType.IsArray)
                    {
                        var fromValue = fromProperty.GetValue(input);
                        var count = Convert.ToInt64(fromProperty.PropertyType.GetProperty("Length").GetValue(fromValue));

                        Array toArray = Array.CreateInstance(toProperty.PropertyType.GetElementType(), new long[] { count });
                        for (int i = 0; i < count; i++)
                        {
                            var currentFromItem = ((object[])fromValue)[i];
                            if (toProperty.PropertyType == fromProperty.PropertyType)
                            {
                                toProperty.SetValue(toArray, currentFromItem, new object[] { i });
                            }
                            else
                            {
                                //and the generic type according to the target property
                                var t = typeof(CopiedObject<>).MakeGenericType(toProperty.PropertyType.GetElementType());


                                var createMethodInfo = t.GetMethod("Create", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic).MakeGenericMethod(new[] { toProperty.PropertyType.GetElementType() });
                                var @object = createMethodInfo.Invoke(null, new[] { currentFromItem });

                                //if the object is not null, set the target property with it
                                if (@object != null)
                                    ((System.Collections.IList)toArray)[i] = @object;
                                    //toProperty.SetValue(toArray, @object, new object[] { i });
                            }
                        }

                        toProperty.SetValue(to, toArray);
                    }
                    else
                    {
                        to.nonMappedProperties.Add(toProperty.Name);
                    }
                }
                else
                {
                    to.nonMappedProperties.Add(toProperty.Name);
                }
            }

            return to;
        }
    }
}
