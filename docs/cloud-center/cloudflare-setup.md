# Cloudflare read-only setup

Implementation: `CloudMonitor.Adapters.Cloudflare`. **Offline contract tests pass; real account authorization and returned data remain unverified until the opt-in smoke tests succeed.** No credentials were discovered or used during implementation.

## Server configuration and permissions

Use an account-scoped Bearer API token referenced by an explicitly named environment variable (`env:HOMELAB_CF_READ_TOKEN`) or an absolute read-only secret file (`file:/run/secrets/cloudflare-read-token`). The adapter calls `Credentials.read/1` on that exact reference. It does not inspect browser sessions, default credential files or other environment variables. Keep the token on the server; never place it in Flutter settings or game JSON.

Add a connection and corresponding authoritative billing scope to the backend's operator configuration:

```json
{
  "id": "cf-main",
  "provider": "cloudflare",
  "displayName": "Cloudflare",
  "billingScopeId": "cf-account",
  "credentialRef": "env:HOMELAB_CF_READ_TOKEN",
  "settings": {
    "accountId": "YOUR_ACCOUNT_ID",
    "metrics": {
      "workers": ["YOUR_SCRIPT_NAME"],
      "r2Buckets": ["YOUR_DEFAULT_JURISDICTION_BUCKET"],
      "zones": ["YOUR_ZONE_ID"]
    }
  }
}
```

The scope uses `provider: cloudflare`, the same `accountId`, and `authoritativeConnectionId: cf-main`. Multiple token aliases for the same account must share that billing scope; they are not additive accounts. Registration of the adapter in the application registry is handled by the backend integration.

Grant only the enabled read capabilities, scoped to this account and its selected zones: Zone / Zone / Read for inventory; Account / Workers Scripts / Read; Account / Workers R2 Storage / Read; Account / Account Analytics / Read for account GraphQL datasets; Zone / Analytics / Read for the optional zone dataset. Product plan, retention, token type and dataset availability can further restrict analytics. No write or metric-enablement calls are made.

Billable Usage is a **Version 1 Alpha** capability. Its public reference describes Bearer authentication but does not provide a universal token permission recipe or guarantee access for every account. Verify access to both billing endpoints with the intended account/token; generic analytics access is not proof of billing access. Permission/authentication failures are returned explicitly and preserve prior snapshots.

## Endpoints and coverage

| Dataset | Real read path | Coverage and limits |
|---|---|---|
| Costs | `GET /accounts/{account}/billable-usage/info`, then `GET /accounts/{account}/billable-usage?from=YYYY-MM-DD&to=YYYY-MM-DD` | Info supplies `covered` and subscription anchor timestamps. `from` includes anchors; historical lookback includes the preceding calendar month without inventing a billing end. The query uses the caller's end date, then retains overlapping native charge periods. |
| Zones | `GET /zones?account.id=...&page=...&per_page=50` | Validate returned account identity; follow numbered pages completely. |
| Workers | `GET /accounts/{account}/workers/scripts` | Documented single-page script inventory; reject an unexpected multi-page contract. |
| R2 | `GET /accounts/{account}/r2/buckets?per_page=100&cursor=...` | Follow returned cursors completely; default jurisdiction only. EU/US/FedRAMP inventories are not included or presented as covered. |
| Workers metrics | `POST /graphql`, `workersInvocationsAdaptive` | Configured scripts only; `sum.requests` and `sum.errors`, unit `count`, requested UTC window. Adaptive sampling remains a limitation. |
| R2 operations | `POST /graphql`, `r2OperationsAdaptiveGroups` | Configured default-jurisdiction buckets; `sum.requests`, unit `count`. No operations are inferred from charges. |
| R2 storage | `POST /graphql`, `r2StorageAdaptiveGroups` | Latest source observation in the requested window, ordered `datetime_DESC`, `max.payloadSize` and `max.metadataSize`, unit `bytes`. A one-microsecond `pointObservation` interval encodes the source timestamp; it does not assert continuous gauge coverage. No interpolation or invented source watermark. |
| Zone requests | `POST /graphql`, `httpRequests1hGroups` | Explicit zone IDs belonging to this account; `sum.requests`, unit `count`. Plan-dependent optional capability. |

`ContractedCost` is a `period` record. `CumulatedContractedCost` is a separate `cumulative` record and is excluded by the existing period-total aggregation. `BilledCost`, `EffectiveCost` and `ListCost` are not added again. Stable record identity excludes amounts, so later adjustments replace the prior values. Unknown/new services are retained, independent of the inventory support list; resource costs remain unallocated (`resourceId: null`). Original charge windows and the native billing-period start are preserved. No billing-period end, final invoice status or forecast is invented.

**Fixed subscriptions, invoice history and proof of complete billing coverage are not included.** Successful metered costs always carry `fixedSubscriptionsUncovered`, `complete: false` and `state: partial`. A returned metered zero is retained as zero within that limited coverage. Empty results, absent anchors and missing cost fields cannot establish zero spend: they return `waiting` or `unsupported` and leave persisted rows/source timestamps intact.

If the info endpoint alone is unavailable/forbidden, an operator may explicitly provide `settings.billingAnchors` as an array of ISO-8601 UTC timestamps. Only this explicit configuration permits the documented billable-usage request without info access. Missing or invalid anchors do not trigger guesses or synthetic data. Authentication and rate-limit errors are not bypassed.

The current v2 `/billable/usage` reference notes that price fields are not yet populated. It is not substituted for v1 amounts. The implementation makes no fabricated `POST billing/usage/paygo` request.

## Bounded requests and status semantics

`collect/4` accepts the existing injectable `:http` module and bounds `:request_budget` (default 100), `:max_pages` (100), `:max_resources` (1,000), `:max_records` (10,000). Resources share the request/resource budget across all three inventories. Failed pages, cycles, record caps, malformed rows and GraphQL responses containing errors return no publishable snapshot. There are no adapter-level retries. HTTP 429/503 preserve an integer Retry-After for the scheduler; authentication, permissions and unsupported endpoints remain distinct.

Metrics are opt-in and have a maximum 31-day query window; source plans may impose shorter retention/windows. Use a recent one-day interval for initial validation. Counters request no grouping dimensions, producing one complete-window aggregate; unexpected multiple aggregate rows are rejected. Inclusive GraphQL end filters receive `end - 1 microsecond` to preserve the API's `[start,end)` contract. R2 gauges intentionally select the latest observation rather than summing snapshots. Unknown/empty metrics preserve prior samples. Dataset source names, units, window/point granularity and aggregation are carried on each sample. Source completeness and `sourceAsOf` remain unknown; a successful HTTP request does not advance a fabricated billing watermark.

## Verification

From `services/cloud_monitor`, with the documented PostgreSQL test service running:

```sh
mix test test/adapters/cloudflare_test.exs test/adapters/cloudflare_snapshot_test.exs test/adapters/cloudflare_live_test.exs
```

The live tests skip unless explicitly enabled. They do not provision or alter cloud resources, but real read API requests may consume account quotas. Configure only the desired identity and reference, and a window containing known activity:

```sh
export CLOUD_MONITOR_CF_LIVE=1
export CLOUD_MONITOR_CF_ACCOUNT_ID='YOUR_ACCOUNT_ID'
export CLOUD_MONITOR_CF_CREDENTIAL_REF='file:/run/secrets/cloudflare-read-token'
export CLOUD_MONITOR_CF_START='2026-10-15T00:00:00Z'
export CLOUD_MONITOR_CF_END='2026-10-16T00:00:00Z'
export CLOUD_MONITOR_CF_WORKERS='YOUR_SCRIPT_NAME'
export CLOUD_MONITOR_CF_R2_BUCKETS='YOUR_BUCKET_NAME'
# Optional: CLOUD_MONITOR_CF_ZONES and CLOUD_MONITOR_CF_BILLING_ANCHORS,
# comma-separated explicit IDs / UTC timestamps respectively.
mix test test/adapters/cloudflare_live_test.exs --trace
```

Real costs, inventory and at least one configured metric must verify independently. A waiting/unsupported billing response fails the live assertion and is not counted as billing success. Output contains only dataset, record count and sanitized state/error, never the token or response body. Three skipped tests are **not** evidence of a live account connection.

## Official references inspected on 2026-10-17

- [Billable Usage v1 Alpha](https://developers.cloudflare.com/api/resources/billing/subresources/usage/methods/get_account_usage_v1/): GET method, `from`/`to`, subscription anchor requirement and wire cost fields.
- [Billable Usage Info v1 Alpha](https://developers.cloudflare.com/api/resources/billing/subresources/usage/methods/get_account_usage_info_v1/): documented info endpoint and subscription metadata.
- [Official generated v1 response model](https://github.com/cloudflare/cloudflare-python/blob/main/src/cloudflare/types/billing/usage_get_account_usage_v1_response.py): native fields, missing authoritative billing-period end and already-numeric source precision.
- [Official generated R2 list client](https://github.com/cloudflare/cloudflare-python/blob/main/src/cloudflare/resources/r2/buckets/buckets.py): cursor pagination and jurisdiction scope.
- [Official generated Workers scripts client](https://github.com/cloudflare/cloudflare-python/blob/main/src/cloudflare/resources/workers/scripts/scripts.py): single-page script listing.
- [Workers GraphQL metrics](https://developers.cloudflare.com/analytics/graphql-api/tutorials/querying-workers-metrics/), [R2 metrics](https://developers.cloudflare.com/r2/platform/metrics-analytics/), [GraphQL datasets](https://developers.cloudflare.com/analytics/graphql-api/features/data-sets/) and [analytics token permissions](https://developers.cloudflare.com/analytics/graphql-api/getting-started/authentication/api-token-auth/).

Amounts received as JSON floating-point numbers are labeled `jsonNumberAlreadyRounded`; decimal strings are retained exactly. Conversion does not recover precision already lost upstream.
