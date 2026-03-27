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

        public RegexAutoUnblockEntry() { }

        public RegexAutoUnblockEntry(string pattern, string description)
        {
            RegexPattern = pattern;
            Description = description;
        }
    }
}
