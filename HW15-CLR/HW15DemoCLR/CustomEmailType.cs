namespace HW15DemoCLR
{
    using Microsoft.SqlServer.Server;
    using System;
    using System.Data.SqlTypes;
    using System.IO;
    using System.Text.RegularExpressions;

    [Serializable]
    [SqlUserDefinedType(
        Format.UserDefined,
        IsByteOrdered = true,
        IsFixedLength = false,
        MaxByteSize = 30)]
    public class CustomEmailType : INullable, IBinarySerialize
    {
        private const string EmailRegexPattern = "^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$";
        private string _email;

        public SqlString Email
        {
            get => _email;

            set
            {
                var inputValue = (string)value;

                if (string.IsNullOrEmpty(inputValue))
                {
                    throw new ArgumentException("Value can't be NULL or Empty", nameof(Email));
                }

                if (!IsValidInputEmail(inputValue))
                {
                    throw new ArgumentException("Invalid input email", nameof(Email));
                }

                _email = inputValue;
            }
        }

        public bool IsNull => string.IsNullOrEmpty(_email);

        public override string ToString() => _email;

        public static CustomEmailType Null => new CustomEmailType();

        public static CustomEmailType Parse(SqlString inputValue)
            => inputValue.IsNull
            ? Null
            : new CustomEmailType
            {
                Email = inputValue
            };

        public void Read(BinaryReader r) => _email = r.ReadString();

        public void Write(BinaryWriter w) => w.Write(_email);

        private bool IsValidInputEmail(string inputValue) => Regex.IsMatch(inputValue, EmailRegexPattern);
    }
}
