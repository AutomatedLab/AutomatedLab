using System;
using System.Collections.Generic;
using System.Linq;

namespace AutomatedLab.Azure
{
    [Serializable]
    public class CopiedObject<T> where T : CopiedObject<T>, new()
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

        public void Merge(T input)
        {
            //run over all properties and take the property value from the input object if it is empty on the current object
            var fromProperties = input.GetType().GetProperties();
            var toProperties = GetType().GetProperties();

            foreach (var toProperty in toProperties)
            {
                //get the property with the same name, the same generic argument count
                var fromProperty = fromProperties.Where(p => p.Name == toProperty.Name &&
                    p.PropertyType.GenericTypeArguments.Count() == toProperty.PropertyType.GenericTypeArguments.Count()).FirstOrDefault();

                var fromValue = fromProperty.GetValue(input);
                var toValue = toProperty.GetValue(this);

                if (fromProperty != null && ((toValue == null && fromValue != null)))
                {
                    toProperty.SetValue(this, fromValue);
                }
            }

        }

        public static T Create(object input) 
        {
            if (input == null)
                throw new ArgumentException("Input cannot be null");

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
                    else if (fromProperty.PropertyType.IsGenericType && typeof(Nullable<>) == fromProperty.PropertyType.GetGenericTypeDefinition() && fromProperty.PropertyType.GetGenericArguments()[0].IsEnum)
                    {
                        var intValue = 0;

                        var t = typeof(Nullable<>).MakeGenericType(toProperty.PropertyType.GetGenericArguments());
                        var value = fromProperty.GetValue(input);
                        if (value != null)
                        {
                            intValue = Convert.ToInt32(value);
                        }

                        object o = value == null ? Activator.CreateInstance(t) : Activator.CreateInstance(t, intValue);
                        toProperty.SetValue(to, o);
                    }
                    //else if (fromProperty.PropertyType.IsInterface || fromProperty.PropertyType == toProperty.PropertyType || toProperty.PropertyType == typeof(string))
                    else if (fromProperty.PropertyType == toProperty.PropertyType || toProperty.PropertyType == typeof(string))
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
                    else if (toProperty.PropertyType.IsGenericType && typeof(IList<>) == fromProperty.PropertyType.GetGenericTypeDefinition() && toProperty.PropertyType.GetGenericArguments()[0].BaseType.IsGenericType && toProperty.PropertyType.GetGenericArguments()[0].BaseType.GetGenericTypeDefinition() == typeof(CopiedObject<>))
                    {
                        //get the source value
                        var value = fromProperty.GetValue(input);

                        //and the generic type according to the target property
                        var t = typeof(CopiedObject<>).MakeGenericType(toProperty.PropertyType.GetGenericArguments()[0]);
                        //var itemType = value.GetType().GetGenericArguments()[0];

                        var toList = Activator.CreateInstance(toProperty.PropertyType);
                        //retrieve the static method "Create" and create a new object
                        var createMethodInfo = t.GetMethod("Create", new Type[] { toProperty.PropertyType });

                        //get the property 'Item' from the input property list
                        var itemProp = value.GetType().GetProperty("Item");
                        //get the length of the input property list
                        var length = (int)value.GetType().GetProperty("Count").GetValue(value);
                        //get the 'Add' method of the toList
                        var addMethod = toProperty.PropertyType.GetMethod("Add", System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.Public);

                        //iterate over the incoming list
                        for (int i = 0; i < length; i++)
                        {
                            //get the current value from the incoming list
                            var o = itemProp.GetValue(value, new object[] { i });
                            //create a new object of the destination type for each incoming object
                            var @object = createMethodInfo.Invoke(null, new[] { o });
                            //and add it to the toList
                            addMethod.Invoke(toList, new object[] { @object });
                        }

                        //if the length is not 0, set the target property with it
                        if (length > 0)
                            toProperty.SetValue(to, toList);
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

        public static IEnumerable<T> Create(object[] input) 
        {
            if (input != null)
            {
                foreach (var item in input)
                {
                    yield return Create(item);
                }
            }
            else
            {
                yield break;
            }
        }
    }
}
