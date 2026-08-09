---
name: walley-bruno
description: "Run Walley Bruno/Edge requests locally: test customers, purchases, notify flows, SE/NO/FI/DK. Triggers: 'add direct invoice', 'create a test customer'."
---

# Walley Bruno

Drive the `walley-bruno` collections from the CLI: seed test people, create purchases of a given
account type, notify accounts/installments, inspect results through PublicWebApi.

Repo: `~/Dev/walley-bruno`. Collection root for everything below:
`~/Dev/walley-bruno/Walley/collections/Edge`.

**Read `~/Dev/walley-bruno/AGENTS.md` before acting.** It is the domain map and always current with
the repo: environment × market table with partner IDs, `invoice_type` codes per product, request
template locations, ready-made scenario folders, old vs new dunning, partner selection, variable
ownership. This skill covers only how to get started and the recipes.

## Bootstrap

```bash
cd ~/Dev/walley-bruno && npm install
az login && az account set --subscription "Walley - CORE"   # VPN required
```

Run from the collection root, always with `--sandbox=developer`:

```bash
cd ~/Dev/walley-bruno/Walley/collections/Edge
npx -y @usebruno/cli run '<request>.bru' --env 'CI - B2C - Sweden' --sandbox=developer
```

The CLI cannot resolve `{{$secrets...}}`. Fetch from `kv-walley-bruno-core` and inject:

| Variable | Secret |
|---|---|
| `payment_service_password` / `invoice_service_password` | `EDGE--ci-payment-service-password` |
| `payment_service_username` / `invoice_service_username` | `EDGE--ci-payment-service-username` |
| `public_web_api_client_secret` | `EDGE-CARLOS--curity-preprod-payments-manual-test-client` |

```bash
az keyvault secret show --vault-name kv-walley-bruno-core --name <secret> --query value -o tsv
```

Environments are named `CI - B2C - Sweden|Norway|Finland|Denmark`, `CI - B2B - Sweden|Norway|Finland`,
`UAT - B2C - Sweden|Norway|Finland`. Pick country **and** customer type; partner IDs and currency
come with it.

## Recipe: create a customer and add a purchase

A purchase flow has no create-customer step — an AddInvoice for a generated person creates the
customer. (`PublicWebApi/Customers/Create customer.bru` creates a bare customer record with no
account, rarely what a test needs.)

1. Generate the person — `Edge/Test data/` (per market; see AGENTS.md for which file).
2. Mock credit data if the flow needs it — `Edge/Mock-service/Mocks/`.
3. AddInvoice for the product — `Edge/PaymentServiceV10/{B2C,B2B}/AddInvoice/AutoActivated/<Product>.bru`,
   or `Pending/` when it should not auto-activate.
4. Resolve IDs — `PublicWebApi/Customers/Get customer.bru` or the transaction search request.
5. Notify / pay — old process via Accounts, new dunning via Installments.

Before stitching requests by hand, check `Edge/Test scenarios/{B2C,B2B}/` and
`_Teamy Labs/Workflows/` — a matching sequence usually exists and runs at folder level.

Worked example, NO customer + DirectInvoice:

```bash
cd ~/Dev/walley-bruno/Walley/collections/Edge
PW=$(az keyvault secret show --vault-name kv-walley-bruno-core \
  --name EDGE--ci-payment-service-password --query value -o tsv)
npx -y @usebruno/cli run 'Test data/Generate new NO person using local algorithm.bru' \
  --env 'CI - B2C - Norway' --sandbox=developer --output /tmp/person.json
# read regno/name/address from /tmp/person.json, then:
npx -y @usebruno/cli run 'PaymentServiceV10/B2C/AddInvoice/AutoActivated/DirectInvoice.bru' \
  --env 'CI - B2C - Norway' --sandbox=developer \
  --env-var payment_service_password="$PW" \
  --env-var registration_number=<regno> --env-var first_name=<..> --env-var last_name=<..> \
  --output /tmp/purchase.json
```

Separate `bru run` processes share no state — hence passing the person forward with `--env-var`.
Running a folder in one process, or using Bruno Desktop, chains automatically.

## Gotchas

- Run from the collection root, not the repo root, or unrelated `.bru` files pollute the parse.
- Scripts run collection → folder → request. Out of folder context, `invoice_type`,
  `activation_option`, `invoice_rows` and `order_number` are never set.
- `--sandbox=developer` is required wherever scripts `require()` (Edge helpers, `xml2js`).
- `DENIED_TO_PURCHASE` on credit accounts is a business denial — retry with a fresh person.
- IDs committed in env files are stale leftovers. Never assume they resolve.
- SE Skatteverket generation picks a random `skv_offset` each run, so it can return an already-used
  person. On a collision, or when Skatteverket is unreachable, switch to
  `_Teamy Labs/Generate Customers/SE Customer (Random).bru`.
- A raw `PaymentServiceV10` AddInvoice builds a **600-row** invoice —
  `PaymentServiceV10/folder.bru` sets `add_invoice_article_count: 600`. `Test scenarios/` overrides
  it to 5 rows / 2000; otherwise pass `--env-var add_invoice_article_count=5`.

## Deeper reference

In-repo SKILL.md files, readable directly: `plugins/bruno/skills/` (`bruno-using`,
`bruno-authoring`, `bruno-secrets`, `bruno-troubleshooting`, `bruno-install`) and
`plugins/edge/skills/` (`edge-authentication`, `edge-requests`, `edge-purchase`).
Writing new `.bru` files → `bruno-authoring`. Node e2e suites and their env overrides → repo
`README.md`.
