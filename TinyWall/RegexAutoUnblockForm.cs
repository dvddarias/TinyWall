using System;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace pylorak.TinyWall
{
    public partial class RegexAutoUnblockForm : Form
    {
        public RegexAutoUnblockEntry Entry { get; private set; }

        public RegexAutoUnblockForm(RegexAutoUnblockEntry? existing = null)
        {
            InitializeComponent();

            Entry = existing ?? new RegexAutoUnblockEntry();
            txtPattern.Text = Entry.RegexPattern;
            txtDescription.Text = Entry.Description;
        }

        private void btnOK_Click(object sender, EventArgs e)
        {
            string pattern = txtPattern.Text.Trim();
            if (string.IsNullOrEmpty(pattern))
            {
                MessageBox.Show(this, "Please enter a regex pattern.", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                _ = new Regex(pattern, RegexOptions.IgnoreCase, TimeSpan.FromMilliseconds(100));
            }
            catch (ArgumentException ex)
            {
                MessageBox.Show(this, $"Invalid regex pattern:\n{ex.Message}", "Validation Error", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            Entry = new RegexAutoUnblockEntry(pattern, txtDescription.Text.Trim());
            DialogResult = DialogResult.OK;
            Close();
        }
    }
}
