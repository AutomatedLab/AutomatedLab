using System;
using System.Collections.Generic;
using System.Linq;
using System.Security;
using System.Text;

namespace AutomatedLab
{
    static class Extensions
    {
        public delegate TOut Action2<TIn, TOut>(TIn element);

        public static IEnumerable<TOut> ForEach<TIn, TOut>(this IEnumerable<TIn> source, Action2<TIn, TOut> action)
        {
            if (source == null) { throw new ArgumentException(); }
            if (action == null) { throw new ArgumentException(); }

            foreach (TIn element in source)
            {
                TOut result = action(element);
                yield return result;
            }
        }

        public static void ForEach<T>(this IEnumerable<T> source, Action<T> action)
        {
            if (source == null) { throw new ArgumentException(); }
            if (action == null) { throw new ArgumentException(); }

            foreach (T element in source)
            {
                action(element);
            }
        }

        public static void AppendString(this SecureString secureString, string s)
        {
            foreach (var c in s)
            {
                secureString.AppendChar(c);
            }
        }

        public static T Copy<T>(this object from) where T : class, new()
        {
            T to = new T();

            var toProperties = to.GetType().GetProperties().Where(p => p.CanWrite).ToList();
            var fromProperties = from.GetType().GetProperties();

            foreach (var toProperty in toProperties)
            {
                var fromProperty = fromProperties.Where(p => p.Name == toProperty.Name && p.PropertyType == toProperty.PropertyType).FirstOrDefault();

                if (fromProperty != null)
                {
                    toProperty.SetValue(to, fromProperty.GetValue(from));
                }
            }

            return to;
        }
    }
}