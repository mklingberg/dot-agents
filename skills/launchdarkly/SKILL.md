---
name: launchdarkly
description: "LaunchDarkly flags in the Teamy C# stack: create/use/test/remove FeatureFlag<T> classes, plus the LD REST API. Triggers: 'add a feature flag', 'is flag X on in prod', 'toggle the flag'."
---

<config>
Everything account- or team-specific lives here. Fork the skill, edit this block,
leave the rest alone.

| Setting | Value |
|---|---|
| Project key | `after-purchase` (171 flags) |
| API base | `https://app.launchdarkly.com/api/v2` |
| Token env var | `LAUNCHDARKLY_PAT` |
| Token source | login keychain `orca-launchdarkly-token`, published by `~/.config/secrets/environment-secrets.sh` at login |
| Token identity | service token "Marcus Klingberg MCP" — writes are attributed to it, not to a person |
| MCP server | **removed on purpose — do not re-add.** See `<integration>` |
| Critical environments | `production` only (`critical=true`); everything else is `false` |

```bash
LD="https://app.launchdarkly.com/api/v2"
PROJ="after-purchase"
```

### Environments

The four this skill ever touches:

| Key | Use |
|---|---|
| `marcus-klingberg-dev` | the operator's own development environment |
| `ci` | shared CI |
| `uat` | shared UAT |
| `production` | live customers, the only `critical=true` environment |

The project has 17 environments; the other 13 are **other developers' personal
environments — never touch them**, not to enable, disable, or tidy up. If a task seems to
need one, stop and ask. List them with the environments call in `references/rest-api.md`
if you need to read state, but treat them as read-only property of their owner.

"Dev" always means `marcus-klingberg-dev`.
</config>

<essential_principles>
## The two halves

A feature flag exists twice: as a **C# class** in the codebase and as a **flag in
LaunchDarkly**. Neither half works alone. Creating one without the other is the most
common failure — a class whose key matches nothing evaluates to the SDK default forever,
silently.

## Codebase rules

### Every flag is a class
Flags live in a project-specific directory. Find it by searching for an existing class
that inherits `FeatureFlag<bool>` — all flags in the project are co-located there. Each
flag is a dedicated `.cs` file inheriting `FeatureFlag<bool>` (from
`Collector.Common.FeatureFlags`).

```csharp
public class JIMS1234_My_New_Flag : FeatureFlag<bool>
{
    public override string Keyname => "teamy-f061bc7f-7d02-4996-b1b9-59b282199e29";
}
```

### Never access ILdClient directly
All evaluation goes through `IFeatureFlagProvider.IsFeatureEnabled<T>()`, injected from DI.
Never call `ldClient.BoolVariation(...)` yourself.

### Continuous deployment — flags are mandatory
Every merge to main goes live immediately in all environments, so **every
behaviour-changing code change must be gated by a flag**. Never merge a behaviour change
unguarded.

Rollout: CI → UAT → PROD, toggling on and verifying at each step before advancing. Once
confirmed in PROD, run the remove-flag workflow.

### Naming
- **Class name / file name:** `JIMS####_Short_Description`, matching the Jira ticket
- **Flag name in LD:** identical to the class name
- **Keyname / LD key:** `teamy-{guid}`, a fresh GUID, unrelated to the class name

### Context is automatic
`LdContextFactory` resolves the user context from the current request (scoped DI). Users
are assigned to numbered groups per country, stored in Elasticsearch; internal beta groups
are configured per environment in `LaunchDarklyOptions:ContextMap`. Don't build context
manually.

## Platform rules

### Flags change running production behaviour
The API has no dry-run and no undo. A `turnFlagOn` against `production` reaches live
customers within seconds. Treat every write as a deploy.

### Never write without explicit confirmation
Before any POST/PATCH/DELETE, show the user the flag key **and** name (the key is a
meaningless UUID — the name is what humans recognise), every environment key that will be
touched, and the exact instruction. Then wait. Reads need no confirmation.

### Never touch another developer's environment
Writes go to `marcus-klingberg-dev`, `ci`, `uat`, `production` and nowhere else. The
other 13 environments belong to other people; flipping a flag in one of them changes
someone else's local behaviour with no warning and no attribution to them.

### Rollout order is fixed
`marcus-klingberg-dev` → `ci` → `uat` → `production`, verifying at each step before
advancing. Don't batch them into one loop.
</essential_principles>

<integration>
## How to talk to LaunchDarkly

**Raw REST with a token. There is no fallback.**

```bash
curl -s -H "Authorization: $LAUNCHDARKLY_PAT" "$LD/flags/$PROJ/<flag-key>"
```

The token goes in a plain `Authorization` header — no `Bearer` prefix. Never echo,
log, or paste it; always reference `$LAUNCHDARKLY_PAT`.

### The MCP server was removed — do not re-add it

`@launchdarkly/mcp-server` was configured in both pi and Claude Code and is now gone
from both. It was removed because it reads its credential **only** from the `--api-key`
argument. Given a token via an `LD_ACCESS_TOKEN` env var instead, it starts happily,
runs unauthenticated, and answers every single call with:

```
Invalid account ID header
```

That error means *no credential was sent*. It does not mean the token is bad, the
account is wrong, or a header needs fixing — and it cost an afternoon of debugging
exactly those three theories. If you meet this string anywhere, something is calling
LD without credentials.

It also cost 20 tool definitions of context in every conversation, offered no
semantic-patch targeting, and duplicated the token into two harness config files that
promptly drifted apart. REST covers strictly more of the API. Don't bring it back.

### Verify auth before writing

```bash
curl -s -H "Authorization: $LAUNCHDARKLY_PAT" "$LD/caller-identity"
```

| Response | Meaning | Action |
|---|---|---|
| `200` + `tokenName`, `accountId` | valid — the `tokenName` says whose writes these will be | proceed |
| `401 {"code":"unauthorized","message":"Invalid key"}` | token dead, revoked, or absent | stop, tell the operator to rotate |
| `Invalid account ID header` | no credential was sent | fix the caller — not the token |

If `$LAUNCHDARKLY_PAT` is empty, the login publisher hasn't run or the keychain item
is missing. Recover with:
```bash
~/.config/secrets/register-secret.sh orca-launchdarkly-token
launchctl kickstart -k gui/$(id -u)/$(launchctl list | awk '/environment-secrets/{print $3}')
```
`launchctl setenv` only reaches processes started afterwards — an already-running
terminal keeps the old (empty) value. Read straight from the keychain to work in the
current shell.
</integration>

<routing>
Route on what the user asked for. Ask the intake question only if intent is genuinely unclear.

| User intent | Read |
|---|---|
| "add a feature flag", "new flag for JIMS####" | `workflows/create-flag.md` |
| "use the flag", "gate this", "inject it into the handler" | `workflows/use-flag.md` |
| "test this", "mock the provider" | `workflows/test-flag.md` |
| "remove the flag", "clean up", "retire" | `workflows/remove-flag.md` |
| "is it on in prod", "toggle it", "list flags", "who turned it on" | `references/rest-api.md` |

Every workflow that touches LaunchDarkly itself sends you to `references/rest-api.md` for
the endpoint and payload. Read it before constructing any call — LD's write payloads are
semantic-patch documents whose failure mode is a `200` that changed nothing.
</routing>

<reference_index>
All in `references/`. Read on trigger, not upfront:

| Read this | When |
|---|---|
| `rest-api.md` | Any LaunchDarkly API call, read or write |
| `flag-structure.md` | Writing or reviewing a flag class file |
| `context-and-sdk.md` | DI wiring, `LdContextFactory`, targeting groups |
| `testing.md` | Mocking `IFeatureFlagProvider` with FakeItEasy |
| `anti-patterns.md` | Reviewing flag usage, or unsure whether a usage is idiomatic |
</reference_index>

<gotchas>
Verified live against `after-purchase`. Add to this list whenever a call surprises you.

- **`Invalid account ID header` = missing credential**, not a bad token and not a header
  to fix. See `<integration>`.
- **No `Bearer` prefix.** `Authorization: api-xxxx…` verbatim. `Bearer api-xxxx…` fails.
- **Semantic patches need their own Content-Type**:
  `application/json; domain-model=launchdarkly.semanticpatch`. Without it the body is
  parsed as a JSON-patch document and you get a confusing 400 — or worse, a 200 that
  changed nothing.
- **429 after ~10 consecutive PATCHes.** Enabling a flag across many environments is a
  loop of single-environment PATCHes; `sleep 4` between them clears it. Check every
  response — a swallowed 429 leaves the flag on in some environments and off in others,
  which is worse than failing outright.
- **One PATCH targets one environment.** `environmentKey` is a scalar. There is no
  bulk-environment call; N environments means N requests.
- **Variation order is the contract.** `[{"value": true}, {"value": false}]` with
  `onVariation: 0`, `offVariation: 1`. Reverse the array and the flag silently means
  the opposite of its name.
- **`GET /flags/{proj}` returns every environment for every flag** — megabytes. Use
  `?summary=true` to list, and `?env=production` to fetch one flag's single environment.
- **Flag keys are opaque UUIDs** (`teamy-<uuid>`), unrelated to the name. Find flags by
  `?filter=query:JIMS2731` — it matches name and key. Verified: returns 2 flags for that
  ticket, so check the name before acting; a ticket can own more than one flag.
- **Deleting is permanent and instant.** Archive (`PATCH … archived: true`) unless the
  operator explicitly said delete. An archived flag can be restored; a deleted one is gone
  and any code still calling it falls through to the SDK default.
- **`lastRequested` is the only real evidence a flag is dead.** `GET /flag-status/{proj}/{key}`
  gives per-environment `name` (`new`/`active`/`inactive`/`launched`) and `lastRequested`.
  `inactive` in every environment with old or null `lastRequested` means nothing is evaluating
  it. Check this before proposing removal — "the code looks unused" is not evidence.
- **Audit log is the fastest way to answer "who turned this on".** `?spec=proj/{proj}:env/{env}:flag/{key}`
  returns `titleVerb` + `member.email`. Plain `?q=` does not filter by flag.
- **Timestamps are epoch milliseconds**, not ISO. `date -r $((ts/1000))`.
</gotchas>

<success_criteria>
- Both halves exist and agree: class `Keyname` is byte-identical to the LD flag key
- Auth verified before any write; `tokenName` known
- Every write confirmed by the user first, with flag name and explicit environment list
- No write to any environment outside `marcus-klingberg-dev`, `ci`, `uat`, `production`
- Rollout advanced one environment at a time, verified before the next
- Endpoints taken from `references/rest-api.md`, not memory
- Every response in a multi-environment loop checked for 429
</success_criteria>
