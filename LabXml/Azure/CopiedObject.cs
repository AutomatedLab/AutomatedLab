using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Xml;

namespace AutomatedLab.Azure
{
    [AttributeUsage(AttributeTargets.Property)]
    public class CustomProperty : Attribute
    {
        //
        // Summary:
        //     Indicates that a property was added and will not be found on the source of the CopiedObject.
    }

    [Serializable]
    public class CopiedObject<T> where T : CopiedObject<T>, new()
    {
        /// <summary>
        ///     Returns an object of type <typeparamref name="T"/> whose value is equivalent to that of the specified 
        ///     object.
        /// </summary>
        /// <typeparam name="T">
        ///     The output type.
        /// </typeparam>
        /// <param name="value">
        ///     An object that implements <see cref="IConvertible"/> or is <see cref="Nullable{T}"/> where the underlying
        ///     type implements <see cref="IConvertible"/>.
        /// </param>
        /// <returns>
        ///     An object whose type is <typeparamref name="T"/> and whose value is equivalent to <paramref name="value"/>.
        /// </returns>
        /// <exception cref="System.ArgumentException">
        ///     The specified value is not defined by the enumeration (when <typeparamref name="T"/> is an enum, or Nullable{T}
        ///     where the underlying type is an enum).
        /// </exception>
        /// <exception cref="System.InvalidCastException"
        /// <remarks>
        ///     This method works similarly to <see cref="Convert.ChangeType(object, Type)"/> with the addition of support
        ///     for enumerations and <see cref="Nullable{T}"/> where the underlying type is <see cref="IConvertible"/>.
        /// </remarks>
        /// 
        private static T ChangeType<T>(object value)
        {

            Type type = typeof(T);
            Type underlyingNullableType = Nullable.GetUnderlyingType(type);

            if ((underlyingNullableType ?? type).IsEnum)
            {
                // The specified type is an enum or Nullable{T} where T is an enum.
                T convertedEnum = (T)Enum.ToObject(underlyingNullableType ?? type, value);

                if (!Enum.IsDefined(underlyingNullableType ?? type, convertedEnum))
                {
                    throw new ArgumentException("The specified value is not defined by the enumeration.", "value");
                }

                return convertedEnum;
            }
            else if (type.IsValueType && underlyingNullableType == null)
            {

                // The specified type is a non-nullable value type.

                if (value == null || DBNull.Value.Equals(value))
                {
                    throw new InvalidCastException("Cannot convert a null value to a non-nullable type.");
                }

                return (T)Convert.ChangeType(value, type);
            }

            // The specified type is a reference type or Nullable{T} where T is not an enum.
            return (value == null || DBNull.Value.Equals(value)) ? default(T) : (T)Convert.ChangeType(value, underlyingNullableType ?? type);
        }
        private List<string> nonMappedProperties;

        public List<string> NonMappedProperties
        {
            get { return nonMappedProperties; }
        }

        public CopiedObject()
        {
            nonMappedProperties = new List<string>();
        }

        public void Merge(T input, string[] ExcludeProperties)
        {
            //run over all properties and take the property value from the input object if it is empty on the current object
            var fromProperties = input.GetType().GetProperties();
            var toProperties = GetType().GetProperties().Where(p => !ExcludeProperties.Contains(p.Name));

            foreach (var toProperty in toProperties)
            {
                //get the property with the same name, the same generic argument count
                var fromProperty = fromProperties.Where(p => p.Name == toProperty.Name &&
                    p.PropertyType.GenericTypeArguments.Count() == toProperty.PropertyType.GenericTypeArguments.Count()).FirstOrDefault();

                var fromValue = fromProperty.GetValue(input);
                var toValue = toProperty.GetValue(this);

                if (fromProperty != null && toProperty.CanWrite)
                {
                    toProperty.SetValue(this, fromValue);
                }
            }
        }

        public void Merge(object input)
        {
            var o = Create(input);
            Merge(o, new string[] { });
        }

        public void Merge(object input, string[] ExcludeProperties)
        {
            var o = Create(input);
            Merge(o, ExcludeProperties);
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
                var fromProperty = fromProperties.Where(
                    p => p.Name.ToLower() == toProperty.Name.ToLower())
                    .FirstOrDefault();

                if (fromProperty != null)
                {
                    //if the type of the fromProperty is a Dictionary<,> of the same type than the SerializableDictionary of the toProperty
                    if (fromProperty.PropertyType.IsGenericType &&
                        fromProperty.PropertyType.GetGenericArguments().Length == 2 &&
                        fromProperty.PropertyType.GetInterfaces().Contains(typeof(IDictionary<,>).MakeGenericType(fromProperty.PropertyType.GenericTypeArguments)))
                    {
                        var t = typeof(SerializableDictionary<,>).MakeGenericType(toProperty.PropertyType.GetGenericArguments());
                        var value = fromProperty.GetValue(input);
                        object o = value == null ? Activator.CreateInstance(t) : Activator.CreateInstance(t, value);
                        toProperty.SetValue(to, o);
                    }
                    //if the type of the fromProperty is a List<> of the same type than the SerializableDictionary of the toProperty
                    else if (fromProperty.PropertyType.IsGenericType &&
                        fromProperty.PropertyType.GetGenericArguments().Length == 1 &&
                        fromProperty.PropertyType.GetInterfaces().Contains(typeof(IList<>).MakeGenericType(fromProperty.PropertyType.GenericTypeArguments)))
                    {
                        var t = typeof(SerializableList<>).MakeGenericType(toProperty.PropertyType.GetGenericArguments());
                        var value = fromProperty.GetValue(input);
                        object o = value == null ? Activator.CreateInstance(t) : Activator.CreateInstance(t, value);
                        toProperty.SetValue(to, o);
                    }
                    //if the type of fromProperty is a Nullable<Enum>
                    else if (fromProperty.PropertyType.IsGenericType &&
                        typeof(Nullable<>) == fromProperty.PropertyType.GetGenericTypeDefinition() &&
                        fromProperty.PropertyType.GetGenericArguments()[0].IsEnum)
                    {
                        var intValue = 0;

                        var t = typeof(Nullable<>).MakeGenericType(toProperty.PropertyType.GetGenericArguments());
                        var value = fromProperty.GetValue(input);
                        if (value != null)
                        {
                            intValue = Convert.ToInt32(value);
                        }

                        //dynamic type casting
                        var changeTypeMethodInfo = typeof(CopiedObject<T>).GetMethod("ChangeType", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic);
                        changeTypeMethodInfo = changeTypeMethodInfo.MakeGenericMethod(toProperty.PropertyType.GenericTypeArguments[0]);
                        var o = changeTypeMethodInfo.Invoke(null, new object[] { intValue });

                        toProperty.SetValue(to, o);
                    }
                    //if the type of fromType is an enum
                    else if (fromProperty.PropertyType.IsEnum && toProperty.PropertyType == typeof(Int32))
                    {
                        var value = fromProperty.GetValue(input);

                        toProperty.SetValue(to, value);
                    }
                    else if (fromProperty.PropertyType.IsEnum && toProperty.PropertyType.IsEnum)
                    {
                        var value = fromProperty.GetValue(input);

                        toProperty.SetValue(to, value);
                    }
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
                    else if (fromProperty.PropertyType == typeof(Hashtable) &&
                        toProperty.PropertyType.GetInterfaces().Contains(typeof(IDictionary<,>).MakeGenericType(toProperty.PropertyType.GenericTypeArguments)))
                    {
                        //get the source value
                        var value = fromProperty.GetValue(input);

                        if (value == null)
                            continue;

                        var d = new Dictionary<string, string>();
                        //KVPs in hashtables will be treated as strings always
                        d = ((IEnumerable)value).Cast<DictionaryEntry>().ToDictionary(kvp => (string)kvp.Key, kvp => (string)kvp.Value);

                        var t = typeof(SerializableDictionary<,>).MakeGenericType(toProperty.PropertyType.GetGenericArguments());
                        object o = value == null ? Activator.CreateInstance(t) : Activator.CreateInstance(t, d);
                        toProperty.SetValue(to, o);
                    }
                    else if (toProperty.PropertyType.IsGenericType && typeof(Dictionary<,>) == fromProperty.PropertyType.GetGenericTypeDefinition() && toProperty.PropertyType.GetGenericArguments()[0].BaseType.IsGenericType && toProperty.PropertyType.GetGenericArguments()[0].BaseType.GetGenericTypeDefinition() == typeof(CopiedObject<>))
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
                else if (fromProperty == null && input.GetType() == typeof(XmlElement))
                {
                    XmlNode attribute = null;
                    var xmlElement = (XmlElement)input;
                    try
                    {
                        attribute = xmlElement.Attributes.Cast<XmlNode>().Where(node => node.Name.ToLower() == toProperty.Name.ToLower()).First();
                    }
                    catch
                    {
                        //it's ok not being able to find the attribute
                    }
                    if (attribute == null)
                    {
                        to.nonMappedProperties.Add(toProperty.Name);
                        continue;
                    }

                    //dynamic type casting
                    var changeTypeMethodInfo = typeof(CopiedObject<T>).GetMethod("ChangeType", System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic);
                    changeTypeMethodInfo = changeTypeMethodInfo.MakeGenericMethod(toProperty.PropertyType);
                    var o = changeTypeMethodInfo.Invoke(null, new object[] { attribute.Value });

                    toProperty.SetValue(to, o);
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
