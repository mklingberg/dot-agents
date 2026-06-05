<overview>
How feature flags are defined and organized in the Walley MyWalley API.
</overview>

<location>
`{flags-directory}/` — exact path varies per project. Find it by locating existing `FeatureFlag<bool>` subclasses (search for `: FeatureFlag<bool>`).

One file per flag.
</location>

<anatomy>
```csharp
using Collector.Common.FeatureFlags;

namespace {YourProject.FeatureFlag.Namespace}; // matches the flags directory — find by reading existing flag files

public class JIMS5690_Missing_Duedate_From_Mx : FeatureFlag<bool>
{
    public override string Keyname => "teamy-f061bc7f-7d02-4996-b1b9-59b282199e29";
}
```

- Inherits `FeatureFlag<T>` from the `Collector.Common.FeatureFlags` package
- Always `bool` unless explicitly different
- `Keyname` must exactly match the key in the LaunchDarkly dashboard
</anatomy>

<naming>
**Class/file name:** `JIMS####_Short_Description` — Jira ticket + PascalCase words joined by underscores

**Keyname:** `"teamy-{guid}"` — always a fresh GUID prefixed with `teamy-`. Generate one with `uuidgen` or any GUID tool. Never derived from the class name.

Note: older flags in this project used descriptive keys (e.g. `"teamy-JIMS####_..."`) before this convention was established. Do not follow that pattern for new flags.
</naming>

<real_examples>
```csharp
// Current convention: GUID keyname, independent of class name
public class JIMS5690_Missing_Duedate_From_Mx : FeatureFlag<bool>
{
    public override string Keyname => "teamy-f061bc7f-7d02-4996-b1b9-59b282199e29";
}

// Kill switch example
public class JIMS4396_Kill_Switch_My_Walley : FeatureFlag<bool>
{
    public override string Keyname => "teamy-316b39b5-2d5a-4358-864c-d7d3c5c3c48b";
}
```
</real_examples>
