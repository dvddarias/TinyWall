using System.Runtime.Serialization;

namespace pylorak.TinyWall
{
    [DataContract(Namespace = "TinyWall")]
    public sealed class RegexAutoUnblockEntry
    {
        [DataMember(EmitDefaultValue = false)]
        public string RegexPattern { get; set; } = string.Empty;

        [DataMember(EmitDefaultValue = false)]
        public string Description { get; set; } = string.Empty;

        [DataMember]
        public bool Enabled { get; set; } = true;

        public RegexAutoUnblockEntry() { }

        public RegexAutoUnblockEntry(string pattern, string description, bool enabled = true)
        {
            RegexPattern = pattern;
            Description = description;
            Enabled = enabled;
        }
    }
}
