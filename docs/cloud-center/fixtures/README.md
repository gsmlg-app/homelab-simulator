# Cloud Center shared fixture v1

`demo-v1.json` is deterministic, synthetic **Demo** data, never a real cloud response or evidence of cloud authorization. Dart and Elixir should load this same file rather than maintain divergent copies. `schemaVersion`, UTC timestamps, camelCase fields and decimal strings match `../api-contract.md`.

- `connections`, `scopes`, `costs`, `resources`, `usage`, `budgets`, `summaries` round-trip through the Dart DTOs.
- `expectedTotals` is the authoritative period overview after alias, parent/child, record-ID and view deduplication. It preserves currency, basis and exact window boundaries. No supported-resource service allowlist is applied.
- `costs` has separate Cloudflare period/cumulative/invoice views, AWS parent/child and alias connections, refunds and credits, a non-calendar period spanning New Year, GCP multiple credits and an invoice month different from the usage month.
- `resources` contains exactly 1,000 stable provider-qualified IDs. `pagination` declares 20 pages of 50. Repositories must page these records; do not create a scene object per resource.
- `scenarios` lists covered conditions. Empty, unconfigured, missing permission, source delay and partial results have distinct dataset states. A recent collection success does not advance `sourceAsOf`.
- Demo repositories must explicitly select mode `demo`, use an isolated cache namespace and display `modeLabel` continuously. Real failures must remain errors; this file is never a real-mode fallback.

Pure Dart calculations are exported by `package:app_cloud/app_cloud.dart`. `DecimalAmount` uses scaled `BigInt`; values are rounded only by presentation code. `aggregateCosts` accepts only authoritative period views and rejects conflicting repeated IDs within one snapshot. `evaluateBudget` evaluates the selected scope independently of parent overview totals; callers supply completeness from the matching dataset. It never writes provider budgets. Zero disables evaluation, and incomplete data below threshold remains unknown.

Model parsing rejects unknown required enum values, absent required values, numeric money and timestamps without a timezone. Nullable optional fields remain null; they never invent freshness or a zero charge. Budget thresholds default to 0.8 and 1 when omitted. Game-console save compatibility and Drift migrations belong to the integration layer rather than these wire DTOs.

Run from `app_lib/cloud`:

```sh
flutter test --no-pub test/cloud_domain_test.dart
dart analyze lib test
```

The Elixir consumer should independently assert `expectedTotals` using Decimal arithmetic and test that importing the same revision again does not add to its snapshot.
