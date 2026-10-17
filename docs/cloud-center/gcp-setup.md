# GCP read-only setup

Implementation: `CloudMonitor.Adapters.GCP`. Offline tests exercise real request contracts with injected HTTP responses. **Real service-account authorization, BigQuery SQL execution and account data remain unverified until the explicit live tests pass.** No cloud credentials were discovered or used during implementation.

## Explicit server configuration

The operator must enable Cloud Billing export to BigQuery beforehand. Standard and Detailed exports share the fields used here; Detailed resource allocation is not implemented. The adapter does not provision exports, enable APIs, create resources or inspect default Google credentials.

Add this connection to the backend operator configuration, with the matching authoritative billing scope:

```json
{
  "id": "gcp-main",
  "provider": "gcp",
  "displayName": "GCP",
  "billingScopeId": "gcp-billing-account",
  "credentialRef": "file:/run/secrets/gcp-read-service-account.json",
  "settings": {
    "queryProject": "query-project",
    "exportTable": "billing-project.billing.export_table",
    "billingAccountId": "ABCDEF-123456-ABCDEF",
    "projects": ["resource-project"],
    "location": "US",
    "cloudRunLocations": ["us-central1"],
    "metrics": [
      {"project": "resource-project", "kind": "gceCpu", "instanceId": "123", "zone": "us-central1-a"},
      {"project": "resource-project", "kind": "gceNetworkReceived", "instanceId": "123", "zone": "us-central1-a"},
      {"project": "resource-project", "kind": "gcsStorage", "bucket": "your-bucket"},
      {"project": "resource-project", "kind": "cloudRunRequests", "service": "your-service", "location": "us-central1"}
    ]
  }
}
```

The billing scope uses `provider: gcp`, `accountId: ABCDEF-123456-ABCDEF` and `authoritativeConnectionId: gcp-main`. Credential aliases for this billing account must share the scope. Choose one authoritative connection covering the desired projects: separate disjoint project connections are not automatically combined as additive billing accounts. In particular, account-level unallocated charges must not be copied into separate additive project scopes.

`queryProject` pays for and runs query jobs; the project in `exportTable` owns the export; `projects` limits resource inventory, metrics and project-attributed costs. These identities are independent. `location` must match the export dataset location (default `US`). Cloud Run inventory requires explicit nonempty `cloudRunLocations`; only those locations are covered. Up to 50 projects and 20 Run locations are accepted. Metric projects must belong to `projects`.

`credentialRef` accepts only an exact `file:/absolute/path` or `env:EXPLICIT_VARIABLE_NAME` through `Credentials.read/1`. Keep secrets server-side. Supported credential JSON:

- A standard `type: service_account` credential with `client_email`, RSA `private_key`, optional `private_key_id`, and `token_uri` absent or exactly `https://oauth2.googleapis.com/token`. OTP signs an RS256 JWT and exchanges it at that fixed Google endpoint. Tokens are acquired per collection and are not persisted.
- An explicitly supplied short-lived token: `{"type":"access_token","access_token":"TOKEN","expires_at":"2026-10-18T00:00:00Z"}`. Expired tokens fail authentication. The operator owns renewal; no default credential lookup occurs.

## APIs and minimum permissions

Enable BigQuery, Compute Engine, Cloud Storage, Cloud Run Admin and Cloud Monitoring APIs for the intended projects as required by Google. API enablement and organization policy are operator prerequisites. The JWT OAuth scope is `https://www.googleapis.com/auth/cloud-platform`; IAM still constrains access.

Grant only the datasets/resources required by the configured connection:

| Source | Required read capabilities |
|---|---|
| BigQuery | `roles/bigquery.jobUser` on the query execution project; `roles/bigquery.dataViewer` on the export dataset, including table metadata/data access. Running SELECT jobs can incur BigQuery query charges despite making no source-data changes. |
| Compute | `roles/compute.viewer` on selected projects, including instance and disk list access. |
| Storage | A custom read role with `storage.buckets.list` on selected projects for bucket inventory. Object content access is unnecessary. Monitoring access is separate. |
| Cloud Run | `roles/run.viewer` on selected projects for service inventory. |
| Monitoring | `roles/monitoring.viewer` on selected projects, including metric descriptor and time-series reads. |

No Billing Account Administrator permission is needed merely to query an already exported dataset. Export setup permissions are separate. Disabled APIs, missing IAM, absent exports and unavailable metric types do not establish zero usage or spend.

## Billing semantics and bounds

The adapter reads export-table metadata, submits fixed parameterized GoogleSQL through `jobs.query`, polls `jobs.getQueryResults` and follows every result page. Identifiers are validated; no caller-provided SQL or filter fragments are accepted. Query jobs have `maximumBytesBilled` (default 1 GB), `jobTimeoutMs: 60000`, a 1-second initial response wait, and bounded polls (default 5). Query rows are limited to the record cap plus one so overflow is detected. Jobs can still consume quota/cost when collection stops waiting; no automatic cancellation or retry is performed.

Usage overlap and billing account filters always apply. Usage-time partitions scan from the requested start minus 93 days through the requested end; export-time partitions scan from requested start through collection time. Ingestion partitions scan whole UTC days from requested start through collection time, allowing late exports after the usage window ends. Legacy nonpartitioned exports retain bounded usage filters and the byte cap; unknown partition fields return unsupported. These bounds intentionally do not claim unlimited historical overlap coverage.

Credits are summed **inside each base export row** before aggregate base cost and credits are summed separately. The base amount and any nonzero credit become distinct period records with basis `GcpExportNetCost`; totals add each exactly once. Original usage intervals and independent `invoice.month` are preserved. Tax, adjustments and unknown services remain present. Unknown cost types retain raw `costType` coverage and category `unknown`; the current adjustment mapping recognizes `adjustment` and `rounding error`.

Amounts use controlled `NUMERIC` arithmetic and decimal strings, with `sourcePrecision: sourceFloat64CastToNumericScale9`. Casting does not recover precision already lost in upstream FLOAT64 values. Resource-level costs remain unallocated (`resourceId: null`), including when using Detailed export.

**Project scope includes account-level unallocated rows.** The query selects `(project.id IN UNNEST(@projects) OR project.id IS NULL)` within the configured billing account. Null-project fees/taxes are retained as `billingAccountUnallocated`, without assigning them to a selected project or resource. Consequently a project-filtered connection includes those billing-account charges and must not be presented as an isolated project's exact subtotal. Other projects' attributed rows are excluded.

Stable record IDs include billing account, project identity (or an internal unallocated marker), service/SKU, native window, currency, invoice month, cost type and base/credit discriminator. Amount and export time are excluded so adjustments replace values. The marker cannot be a valid configured project ID; otherwise identical unallocated and project rows have distinct IDs. Existing billing-scope authority accepts only the authoritative connection, then deduplicates by scope and record ID, retaining both dimensions once and rejecting alias copies.

Successful nonempty costs are always `partial`, `complete: false`: maximum actual `export_time` is a source observation, never proof that an interval is complete. Export latency is not guaranteed. Empty/missing exports return `waiting`; ambiguous emptiness, failed pages, auth failures and permissions do not publish empty costs. Existing Jobs/Store failure handling retains prior rows, snapshot revision and source timestamps. There is no operator switch to treat an empty export as confirmed zero.

## Inventory and metrics

Inventory uses official paginated APIs: Compute aggregated instances/disks (`returnPartialSuccess=false`), Storage bucket list and Cloud Run v2 service list for each configured project/location. Unreachable scopes, non-benign Compute warnings, cursor cycles and failed pages reject the collection. Complete empty lists may publish `empty`. Successful completeness covers only those supported resource types and configured locations; it does not establish all-GCP coverage.

Monitoring reads each fixed metric descriptor before listing time series and validates its kind, unit and numeric type. Resource labels constrain and validate the explicit instance/bucket/service. Metric/resource labels remain part of sample identity so separate series do not collide.

| Kind | Official metric | Kind / native unit | Alignment |
|---|---|---|---|
| `gceCpu` | `compute.googleapis.com/instance/cpu/utilization` | GAUGE / `10^2.%` | Mean, 300 s; retain source fraction (0.5 represents 50%). |
| `gceNetworkReceived` | `compute.googleapis.com/instance/network/received_bytes_count` | DELTA / `By` | Sum, 300 s. |
| `gceNetworkSent` | `compute.googleapis.com/instance/network/sent_bytes_count` | DELTA / `By` | Sum, 300 s. |
| `gcsStorage` | `storage.googleapis.com/storage/total_bytes` | GAUGE / `By` | Maximum, 86400 s. |
| `cloudRunRequests` | `run.googleapis.com/request_count` | DELTA / `1` | Sum, 300 s; revision/response label series remain separate. |

Source intervals are preserved. End-only GAUGE points use a one-microsecond interval marker at the source timestamp; their `granularity` still identifies the requested alignment period and does not imply continuous coverage. Monitoring's `(start,end]` filter bounds receive start/end minus one microsecond to implement the application's `[start,end)` window. Daily storage sampling, source latency/retention, quotas and descriptor availability remain limitations. No interpolation, fabricated latest watermark, or metrics inferred from charges are provided. Empty metrics return `waiting`; absent configuration returns `unconfigured`. Metrics always remain partial.

Shared per-collection bounds include authentication and every dataset request: `request_budget` default 100, `max_pages` 100, `max_resources` 1000 and `max_records` 10000. No partial result is published after a later page fails. Authentication, permission and quota errors remain distinct; integer Retry-After values are capped at one day for the scheduler.

## Scoped verification and explicit live opt-in

From `services/cloud_monitor`, with the documented PostgreSQL test service available:

```sh
mix test test/adapters/gcp_test.exs test/adapters/gcp_auth_test.exs test/adapters/gcp_snapshot_test.exs test/adapters/gcp_live_test.exs --warnings-as-errors
```

The three real-account tests skip unless `CLOUD_MONITOR_GCP_LIVE=1`. For live validation, store exactly the connection object above in a server-side JSON file (its credential remains a separate explicit reference), choose a recent interval containing known exported costs and metrics, then run:

```sh
export CLOUD_MONITOR_GCP_LIVE=1
export CLOUD_MONITOR_GCP_CONFIG_REF='file:/run/secrets/gcp-live-connection.json'
export CLOUD_MONITOR_GCP_START='2026-10-15T00:00:00Z'
export CLOUD_MONITOR_GCP_END='2026-10-16T00:00:00Z'
mix test test/adapters/gcp_live_test.exs --trace
```

These tests read only the exact configuration reference through `Credentials.read/1`, then the adapter reads that connection's exact credential reference. They invoke actual read APIs and a billable bounded BigQuery SELECT job. Each dataset verifies independently; waiting/unsupported costs and empty metrics fail validation. Confirmed empty inventory is valid. Output contains only dataset, count and sanitized state/error, never credentials or response bodies. Default skipped tests provide no live account evidence. No performance measurements or real account verification are claimed by the offline suite.

## Official references inspected on 2026-10-17

- [Standard export schema](https://cloud.google.com/billing/docs/how-to/export-data-bigquery-tables/standard-usage) and [Detailed export schema](https://cloud.google.com/billing/docs/how-to/export-data-bigquery-tables/detailed-usage).
- [BigQuery jobs.query](https://cloud.google.com/bigquery/docs/reference/rest/v2/jobs/query) and [getQueryResults](https://cloud.google.com/bigquery/docs/reference/rest/v2/jobs/getQueryResults).
- [Service-account OAuth JWT flow](https://developers.google.com/identity/protocols/oauth2/service-account).
- [Compute aggregated instances](https://cloud.google.com/compute/docs/reference/rest/v1/instances/aggregatedList), [Storage buckets list](https://cloud.google.com/storage/docs/json_api/v1/buckets/list) and [Cloud Run services list](https://cloud.google.com/run/docs/reference/rest/v2/projects.locations.services/list).
- [Monitoring timeSeries.list](https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.timeSeries/list) and [metricDescriptors.get](https://cloud.google.com/monitoring/api/ref_v3/rest/v3/projects.metricDescriptors/get). Runtime descriptors verify each supported metric's actual contract.
