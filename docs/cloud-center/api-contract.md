# Cloud Center API contract v1

CC-00 frozen integration contract. All dates are ISO-8601 UTC; cost windows use [start,end). Amounts are decimal strings. No cloud secrets cross this API. Schema fields use camelCase on the wire. Unknown fields may be ignored; required field failures are errors, never demo fallback.

## Envelope
Every successful GET returns `{schemaVersion:1, revision:"opaque", query:{...}, data:..., nextCursor:null}`. Errors return `{error:{code:"permissionDenied", message:"sanitized"}}`. Cursor is opaque and bound to query + revision; stale cursor returns HTTP 409 `revisionExpired`. Auth uses `Authorization: Bearer <application token>`. Remote base URLs require HTTPS; explicit localhost development may use HTTP.

## Models
- CloudConnection: id, provider (`cloudflare|aws|gcp`), displayName, billingScopeId, capabilities (dataset to capability), statuses (dataset to DatasetStatus). Never credentials.
- BillingScope: id, provider, parentId nullable, accountId, authoritativeConnectionId. Parent and child views are not additive.
- DatasetStatus: state (`unconfigured|waiting|empty|partial|available|stale|permissionDenied|authenticationFailed|unsupported|rateLimited|failed`), lastAttemptAt, lastSuccessAt, sourceAsOf nullable, observedStart nullable, observedEnd nullable, complete (boolean), reason nullable. Collection time is never a source watermark.
- CostRecord: id, connectionId, billingScopeId, service, resourceId nullable, start, end, currency, amount (decimal string), basis, category (`usage|subscription|tax|credit|refund|adjustment|unknown`), estimated nullable, source, sourcePrecision, invoiceMonth nullable, recordKind (`reported` only), view (`period|cumulative|invoice|detail`), coverage (string list). Only period records in the same authoritative scope, window, currency and basis may aggregate; cumulative/invoice/detail are separate views. Unsupported services are retained.
- CloudResource: id (provider-qualified stable identity), connectionId, billingScopeId, service, type, region, name, tags (map), observedAt, state nullable.
- UsageSample: id, resourceId nullable, service, metric, unit, start, end, granularity, aggregation, value (decimal string), source.
- BudgetRule: id, billingScopeId, currency, start, end, basis, amount (decimal string), thresholds (decimal strings, default 0.8 and 1). Zero budget disables evaluation. Incomplete data below threshold is unknown; above threshold is known exceeded.
- ConsoleSummary: connectionId, provider, amountLabel nullable, currency nullable, start nullable, end nullable, budgetState, dataState. No full ledger.

## Routes
All routes below are relative to `/v1` and read only persisted snapshots unless stated.

| Method/path | data |
|---|---|
| GET /connections | CloudConnection[] |
| GET /cloud-center/overview | {totals:[{currency,basis,start,end,amount}],connections:CloudConnection[],coverage:[]} |
| GET /connections/:id/overview | {connection:CloudConnection,totals:[],resourceCount,statuses:{}} |
| GET /connections/:id/costs | CostRecord[] |
| GET /connections/:id/resources | CloudResource[] |
| GET /resources/:id/usage | UsageSample[] |
| POST /connections/:id/sync | HTTP 202 {id,state}; deduplicated independently of panels |
| GET /sync-jobs/:id | {id,connectionId,dataset,state,attempts,errorCode} |
| GET /budgets | BudgetRule[] |
| PUT /budgets/:id | BudgetRule; writes this application only |

List filters: start/end (maximum 93 days), service, region, project, search, basis, cursor, limit (default 50, maximum 100). `connectionId` selects a connection, never implies all accounts are additive. Query/revision isolation is mandatory. Missing or failed real configuration never returns synthetic data. Demo is a separate repository with persistent visible mode badge and isolated cache namespace.

## Calendar-window totals
Overview `totals` contains comparable period buckets wholly contained in the explicit query window, aggregated with that query start/end and grouped by currency and basis after scope authority deduplication. Overlapping native intervals that cannot map without allocation are returned as optional `unmappedTotals: CostTotal[]`, explicitly excluded from comparison. Consumers retain and label them rather than silently prorating or dropping them. No query window keeps native-window groups intact. Budget evaluation includes daily buckets wholly contained in its rule interval and never prorates a coarse overlapping bucket.

## Integration ownership
Coordinator owns this contract, root workspace registration, PRD and validation report. CC-01 owns existing scene lifecycle only. CC-02 owns app_lib/cloud models and fixtures only. Later integration assigns console models/room registration, backend and UI separately. PostgreSQL stores snapshots and jobs; Drift stores client configuration and bounded isolated cache. Tests must distinguish offline contract evidence from live cloud authorization.
