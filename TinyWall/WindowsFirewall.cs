using System;
using System.Collections;
using System.IO;
using System.Diagnostics.Eventing.Reader;
using pylorak.Utilities;

namespace pylorak.TinyWall
{
    class WindowsFirewall : Disposable
    {
        // Windows Firewall COM enum constants
        private const int NET_FW_ACTION_ALLOW = 1;
        private const int NET_FW_RULE_DIR_IN = 1;
        private const int NET_FW_RULE_DIR_OUT = 2;
        private const int NET_FW_PROFILE2_DOMAIN = 1;
        private const int NET_FW_PROFILE2_PRIVATE = 2;
        private const int NET_FW_PROFILE2_PUBLIC = 4;

        private readonly EventLogWatcher? WFEventWatcher;

        // This is a list of apps that are allowed to change firewall rules
        private static readonly string[] WhitelistedApps = new string[]
        {
#if DEBUG
            Path.Combine(Path.GetDirectoryName(Utils.ExecutablePath)!, "TinyWall.vshost.exe"),
#endif
            Utils.ExecutablePath,
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "dllhost.exe")
        };

        public WindowsFirewall()
        {
            DisableMpsSvc();

            try
            {
                WFEventWatcher = new EventLogWatcher("Microsoft-Windows-Windows Firewall With Advanced Security/Firewall");
                WFEventWatcher.EventRecordWritten += new EventHandler<EventRecordWrittenEventArgs>(WFEventWatcher_EventRecordWritten);
                WFEventWatcher.Enabled = true;
            }
            catch(Exception e)
            {
                Utils.Log("Cannot monitor Windows Firewall. Is the 'eventlog' service running? For details see next log entry.", Utils.LOG_ID_SERVICE);
                Utils.LogException(e, Utils.LOG_ID_SERVICE);
            }
        }

        private static void WFEventWatcher_EventRecordWritten(object? sender, EventRecordWrittenEventArgs e)
        {
            try
            {
                int propidx = -1;
                switch (e.EventRecord.Id)
                {
                    case 2003:     // firewall setting changed
                        {
                            propidx = 7;
                            break;
                        }
                    case 2005:     // rule changed
                        {
                            propidx = 22;
                            break;
                        }
                    case 2006:     // rule deleted
                        {
                            propidx = 3;
                            break;
                        }
                    case 2032:     // firewall has been reset
                        {
                            propidx = 1;
                            break;
                        }
                    default:
                        // Nothing to do
                        return;
                }

                System.Diagnostics.Debug.Assert(propidx != -1);

                // If the rules were changed by us, do nothing
                string EVpath = (string)e.EventRecord.Properties[propidx].Value;
                for (int i = 0; i < WhitelistedApps.Length; ++i)
                {
                    if (string.Compare(WhitelistedApps[i], EVpath, StringComparison.OrdinalIgnoreCase) == 0)
                        return;
                }
            }
            catch { }
            finally
            {
                e.EventRecord?.Dispose();
            }

            DisableMpsSvc();
        }

        protected override void Dispose(bool disposing)
        {
            if (IsDisposed)
                return;

            if (disposing)
            {
                WFEventWatcher?.Dispose();
            }

            RestoreMpsSvc();
            base.Dispose(disposing);
        }

        private static dynamic GetFwPolicy2()
        {
            Type tNetFwPolicy2 = Type.GetTypeFromProgID("HNetCfg.FwPolicy2")!;
            return Activator.CreateInstance(tNetFwPolicy2)!;
        }

        private static dynamic CreateFwRule(string name, int action, int dir)
        {
            Type tNetFwRule = Type.GetTypeFromProgID("HNetCfg.FwRule")!;
            dynamic rule = Activator.CreateInstance(tNetFwRule)!;

            rule!.Name = name;
            rule.Action = action;
            rule.Direction = dir;
            rule.Grouping = "TinyWall";
            rule.Profiles = NET_FW_PROFILE2_PRIVATE | NET_FW_PROFILE2_PUBLIC | NET_FW_PROFILE2_DOMAIN;
            rule.Enabled = true;
            if ((NET_FW_RULE_DIR_IN == dir) && (NET_FW_ACTION_ALLOW == action))
                rule.EdgeTraversal = true;

            return rule;
        }

        private static void MpsNotificationsDisable(dynamic pol, bool disable)
        {
            if (pol.NotificationsDisabled[NET_FW_PROFILE2_PRIVATE] != disable)
                pol.NotificationsDisabled[NET_FW_PROFILE2_PRIVATE] = disable;
            if (pol.NotificationsDisabled[NET_FW_PROFILE2_PUBLIC] != disable)
                pol.NotificationsDisabled[NET_FW_PROFILE2_PUBLIC] = disable;
            if (pol.NotificationsDisabled[NET_FW_PROFILE2_DOMAIN] != disable)
                pol.NotificationsDisabled[NET_FW_PROFILE2_DOMAIN] = disable;
        }

        private static void DisableMpsSvc()
        {
            try
            {
                dynamic fwPolicy2 = GetFwPolicy2();

                // Disable Windows Firewall notifications
                MpsNotificationsDisable(fwPolicy2, true);

                // Add new rules
                string newRuleId = $"TinyWall Compat [{Utils.RandomString(6)}]";
                fwPolicy2.Rules.Add(CreateFwRule(newRuleId, NET_FW_ACTION_ALLOW, NET_FW_RULE_DIR_IN));
                fwPolicy2.Rules.Add(CreateFwRule(newRuleId, NET_FW_ACTION_ALLOW, NET_FW_RULE_DIR_OUT));

                // Remove earlier rules
                dynamic rules = fwPolicy2.Rules;
                var toRemove = new System.Collections.Generic.List<string>();
                foreach (dynamic rule in (IEnumerable)rules)
                {
                    string ruleName = rule.Name;
                    if (!string.IsNullOrEmpty(ruleName) && ruleName.Contains("TinyWall") && (ruleName != newRuleId))
                        toRemove.Add(ruleName);
                }
                foreach (string name in toRemove)
                    rules.Remove(name);
            }
            catch { }
        }

        private static void RestoreMpsSvc()
        {
            try
            {
                dynamic fwPolicy2 = GetFwPolicy2();

                // Enable Windows Firewall notifications
                MpsNotificationsDisable(fwPolicy2, false);

                // Remove earlier rules
                dynamic rules = fwPolicy2.Rules;
                var toRemove = new System.Collections.Generic.List<string>();
                foreach (dynamic rule in (IEnumerable)rules)
                {
                    if ((rule.Grouping != null) && ((string)rule.Grouping).Equals("TinyWall"))
                        toRemove.Add((string)rule.Name);
                }
                foreach (string name in toRemove)
                    rules.Remove(name);
            }
            catch { }
        }
    }
}
