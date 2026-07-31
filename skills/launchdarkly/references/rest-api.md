# LaunchDarkly REST API — verified recipes

Every call below was run against project `after-purchase` and returned what is shown.
Setup assumed in all snippets:

```bash
LD="https://app.launchdarkly.com/api/v2"
PROJ="after-purchase"
AUTH=(-H "Authorization: $LAUNCHDARKLY_PAT")   # no Bearer prefix
```

If `$LAUNCHDARKLY_PAT` is unset in the current shell (the login publisher only reaches
processes started after it ran):

```bash
LAUNCHDARKLY_PAT=$(security find-generic-password -s orca-launchdarkly-token -a "$USER" -w)
```

---

## Reads

### Who am I
```bash
curl -s "${AUTH[@]}" "$LD/caller-identity"
```
```json
{"accountId":"57daae…","authKind":"token","tokenKind":"auth",
 "tokenName":"Marcus Klingberg MCP","serviceToken":true}
```
`tokenName` is what will appear against every write. Run this before any write.

### List environments
```bash
curl -s "${AUTH[@]}" "$LD/projects/$PROJ/environments?limit=25" \
  | jq -r '.items[] | "\(.key)\t\(.name)\tcritical=\(.critical)"'
```
17 items. Only `production` has `critical=true` — use that field to detect
production-like environments rather than matching on the name.

### Find a flag (keys are opaque UUIDs)
```bash
curl -s "${AUTH[@]}" "$LD/flags/$PROJ?limit=20&summary=true&filter=query:JIMS2731" \
  | jq -r '.items[] | "\(.key)\t\(.name)"'
```
Matches name and key. `query:JIMS2731` → 2 flags; `query:Savings` → 5. A ticket number
is not unique — always show the operator the names before acting.

`summary=true` is not optional at scale: without it the response carries every
environment for every flag.

### One flag, all environments
```bash
curl -s "${AUTH[@]}" "$LD/flags/$PROJ/$KEY" \
  | jq '{key,name,temporary,variations:[.variations[].value],
         on:(.environments|to_entries|map({(.key):.value.on})|add)}'
```

### One flag, one environment (small payload)
```bash
curl -s "${AUTH[@]}" "$LD/flags/$PROJ/$KEY?env=production" \
  | jq '.environments.production.on'
```

### Is this flag actually used?
```bash
curl -s "${AUTH[@]}" "$LD/flag-status/$PROJ/$KEY" \
  | jq -r '.environments | to_entries[] | "\(.key)\t\(.value.name)\t\(.value.lastRequested)"'
```
```
ci              inactive   2025-09-…
production      inactive   null
```
`name` ∈ `new` | `active` | `inactive` | `launched`. `inactive` everywhere with old or
null `lastRequested` is the evidence needed before proposing removal.

### Who changed this flag
```bash
curl -s "${AUTH[@]}" "$LD/auditlog?limit=10&spec=proj/$PROJ:env/production:flag/$KEY" \
  | jq -r '.items[] | "\(.date)\t\(.titleVerb)\t\(.member.email)"'
```
```
1641203635830   turned on the flag    bjorn.hagstrom@collectorbank.se
1636024280014   created the flag      $ATLASSIAN_USER
```
`date` is epoch **milliseconds**: `date -r $((1641203635830/1000))`.
The `spec` triple is required — plain `?q=` does not filter by flag.

### Code references
```bash
curl -s "${AUTH[@]}" "$LD/code-refs/statistics/$PROJ?flagKey=$KEY"
```
Returns 200 with counts only if the code-refs scanner runs in CI for this repo. Empty
results mean "not scanned", not "not used" — don't read them as evidence of a dead flag.

---

## Writes

Confirm with the operator first. Show flag name, environment keys, and the instruction.

### Create a boolean flag
```bash
curl -s -X POST "${AUTH[@]}" -H "Content-Type: application/json" \
  "$LD/flags/$PROJ" -d '{
    "key": "teamy-'"$(uuidgen | tr A-Z a-z)"'",
    "name": "JIMS1234_Some_Flag",
    "temporary": true,
    "variations": [{"value": true}, {"value": false}],
    "defaults": {"onVariation": 0, "offVariation": 1}
  }'
```
Order matters: index 0 = `true` = on-variation. Reversing the array makes the flag mean
the opposite of its name, with no error. New flags are off in every environment.

### Toggle in one environment (semantic patch)
```bash
curl -s -X PATCH "${AUTH[@]}" \
  -H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch" \
  "$LD/flags/$PROJ/$KEY" \
  -d '{"environmentKey":"ci","instructions":[{"kind":"turnFlagOn"}]}'
```
The `domain-model=launchdarkly.semanticpatch` parameter is mandatory. Other instruction
kinds: `turnFlagOff`, `addUserTargets`, `removeUserTargets`, `updateFallthroughVariationOrRollout`.

### Toggle across several environments
`environmentKey` is a scalar — one request per environment, and LD rate-limits the loop.

```bash
for ENV in marcus-klingberg-dev ci uat; do
  CODE=$(curl -s -o /tmp/ld-out.json -w '%{http_code}' -X PATCH "${AUTH[@]}" \
    -H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch" \
    "$LD/flags/$PROJ/$KEY" \
    -d "{\"environmentKey\":\"$ENV\",\"instructions\":[{\"kind\":\"turnFlagOn\"}]}")
  echo "$ENV -> $CODE"
  [ "$CODE" = "200" ] || echo "FAILED: $(cat /tmp/ld-out.json)"
  sleep 4
done
```
429 starts after roughly 10 consecutive PATCHes; `sleep 4` clears it. Never run this loop
without checking each status — a partial run leaves the flag on in some environments and
off in others, and the shell reports success.

Then verify, rather than trusting the loop output:
```bash
curl -s "${AUTH[@]}" "$LD/flags/$PROJ/$KEY" \
  | jq -r '.environments | to_entries[] | select(.value.on) | .key'
```

### Rename / retag (JSON patch, not semantic)
```bash
curl -s -X PATCH "${AUTH[@]}" -H "Content-Type: application/json" \
  "$LD/flags/$PROJ/$KEY" \
  -d '[{"op":"replace","path":"/name","value":"JIMS1234_New_Name"}]'
```
Flag-level metadata uses standard JSON patch — an array, no `environmentKey`.
Environment-level targeting uses semantic patch. Mixing the two is the most common 400.

### Archive (reversible — prefer this)
```bash
curl -s -X PATCH "${AUTH[@]}" -H "Content-Type: application/json" \
  "$LD/flags/$PROJ/$KEY" \
  -d '[{"op":"replace","path":"/archived","value":true}]'
```

### Delete (permanent)
```bash
curl -s -X DELETE "${AUTH[@]}" "$LD/flags/$PROJ/$KEY"
```
Only when the operator explicitly said delete rather than archive. Any code still
evaluating the key silently falls through to the SDK default.

---

## Response quick reference

| Status / body | Meaning |
|---|---|
| `200` | fine — but for semantic patches, verify the change actually landed |
| `400` | malformed patch; usually JSON patch sent as semantic or vice versa |
| `401 Invalid key` | token dead or revoked |
| `404` | wrong project, flag, or environment key — check the environment list first |
| `409` | conflict; flag key already exists |
| `429` | rate limited; back off ~4s |
| `Invalid account ID header` | no credential sent at all — the caller is broken, not the token |
