<overview>
Jira Cloud REST API v3 via curl. No MCP, no SDK — a PAT in an environment
variable and `curl` work in any harness on any machine.
</overview>

<auth>
Atlassian Cloud uses **basic auth with an API token**, not a bearer token.
The username is the account email; the password is the token.

```bash
JIRA_SITE="https://norionbank.atlassian.net"
AUTH=(-u "$ATLASSIAN_USER:$ATLASSIAN_PAT")
B="$JIRA_SITE/rest/api/3"
```

Neither the account email nor the token is written into this skill — this repo is
public. `$ATLASSIAN_USER` is the Atlassian account email; `$ATLASSIAN_PAT` is the
API token. Both come from the login keychain, published into the login session by
`~/.config/secrets/environment-secrets.sh` (services `atlassian-user` and
`atlassian-token`).

The email is not a credential, but it is still personal and this repo is public,
so it lives in the keychain for the same reason the token does.

If either is empty, the publisher has not run in this process tree:

```bash
export ATLASSIAN_USER=$(security find-generic-password -s atlassian-user -a "$USER" -w)
export ATLASSIAN_PAT=$(security find-generic-password -s atlassian-token -a "$USER" -w)
```

Permanent fix (then restart the harness) — discover the label rather than
assuming it, since it carries the local account name:
```bash
launchctl kickstart -k gui/$(id -u)/$(launchctl list | awk '/environment-secrets/{print $3}')
```

Verify auth before anything else — a 401 here saves ten confusing errors later:
```bash
curl -s -o /dev/null -w "%{http_code}\n" "${AUTH[@]}" "$B/myself"   # expect 200
```

## Your own accountId

Required as `reporter` on create and as the target when self-assigning. Resolve
it once per session and reuse; do not hardcode it — an accountId is a stable
cross-product identifier for a named person.

```bash
export ATLASSIAN_ACCOUNT_ID=$(curl -s "${AUTH[@]}" "$B/myself" | python3 -c 'import json,sys; print(json.load(sys.stdin)["accountId"])')
```
</auth>

<reading>
**Get an issue** — always name the fields you want. The default response is
enormous and mostly nulls.
```bash
curl -s "${AUTH[@]}" "$B/issue/MS-6545?fields=summary,status,assignee,labels,description,parent,subtasks"
```

**Search (JQL).** The endpoint is `/search/jql`. The old `POST /search` is
deprecated and will 410 on new tenants.
```bash
curl -s -G "${AUTH[@]}" \
  --data-urlencode 'jql=project=MS AND status="To be Refined" ORDER BY created DESC' \
  --data-urlencode 'fields=summary,status,labels' \
  --data-urlencode 'maxResults=50' \
  "$B/search/jql"
```
Response is `{issues, nextPageToken, isLast}` — **cursor pagination, not
`startAt`**. To page, pass `nextPageToken` back as `&nextPageToken=...` until
`isLast` is true. There is no total count; don't promise one to the user.

**Comments:**
```bash
curl -s "${AUTH[@]}" "$B/issue/MS-6545/comment?maxResults=20"
```
</reading>

<writing>
All writes are `Content-Type: application/json`. Description and comment bodies
are **ADF, not markdown** — see `adf.md`.

**Create an issue:**
```bash
curl -s "${AUTH[@]}" -X POST -H "Content-Type: application/json" \
  --data @/tmp/issue.json "$B/issue"
```
Returns `{"id","key","self"}`. Echo the key and the browse URL back to the user:
`https://norionbank.atlassian.net/browse/MS-1234`.

**Create a sub-task** — same endpoint; the parent goes in `fields.parent.key`
and the issue type must be the sub-task type (`10003`), not `Sub-task` by name
in a project where several sub-task types exist.

**Edit fields:**
```bash
curl -s "${AUTH[@]}" -X PUT -H "Content-Type: application/json" \
  --data '{"fields":{"summary":"New summary"}}' "$B/issue/MS-6545"
```
Returns `204` with an empty body. No news is good news.

**Add a comment:** `POST $B/issue/MS-6545/comment` with `{"body": <ADF doc>}`.

**Transition** is a two-step dance — transition ids are per-workflow and per-
current-status, so never hardcode them:
```bash
curl -s "${AUTH[@]}" "$B/issue/MS-6545/transitions"          # discover valid ids now
curl -s "${AUTH[@]}" -X POST -H "Content-Type: application/json" \
  --data '{"transition":{"id":"91"}}' "$B/issue/MS-6545/transitions"
```
</writing>

<discovery>
Run these when something doesn't fit the `<config>` block in SKILL.md — then
update `<config>` rather than rediscovering next time.

```bash
# custom field ids by name
curl -s "${AUTH[@]}" "$B/field" | python3 -c "
import json,sys
for f in json.load(sys.stdin):
    if 'team' in f['name'].lower(): print(f['id'], f['name'])"

# issue types available in the project
curl -s "${AUTH[@]}" "$B/issue/createmeta/MS/issuetypes?maxResults=50"

# required fields + allowed values for one issue type
curl -s "${AUTH[@]}" "$B/issue/createmeta/MS/issuetypes/10001?maxResults=100"
```
`createmeta` is the authority on what a create call will accept. When a create
returns 400, read it before guessing.

**Labels in actual use** — the global `/label` endpoint lists every label on the
whole tenant and is useless for picking one. Sample the project instead:
```bash
curl -s -G "${AUTH[@]}" --data-urlencode 'jql=project=MS AND created > -180d' \
  --data-urlencode 'fields=labels' --data-urlencode 'maxResults=100' "$B/search/jql"
```
</discovery>

<gotchas>
- **Basic auth, not `Authorization: Bearer`.** A bearer token gets a 401 with a
  message that does not mention auth scheme.
- **`/search/jql`, not `/search`.** Cursor pagination via `nextPageToken`; no
  `startAt`, no `total`.
- **Descriptions and comments are ADF.** Sending a plain string 400s.
- **`reporter` is required on create** in MS — omitting it fails even though the
  UI fills it in for you.
- **Story Points is not on the MS Story screen.** Sending `customfield_11072`
  or `customfield_10008` 400s with "field cannot be set".
- **Transition ids are not statuses.** Always `GET /transitions` first; the
  legal set changes with the issue's current status.
- **PUT /issue returns 204 with no body.** Don't parse it as JSON.
- **JQL needs quoting for multi-word values**: `status="To be Refined"`, and the
  whole thing needs `--data-urlencode` — not string interpolation into the URL.
- **Sub-Bug (`10100`) exists** alongside Sub-task (`10003`). Pick by id.
</gotchas>
