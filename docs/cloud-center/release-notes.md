# v0.1.0-cloud-center.1

Cloud Center Phase 1 is prepared as a **source prerelease**. Scoped offline implementation checks are accepted; all real cloud accounts and complete native manual acceptance remain pending. This document does not assert that a tag or GitHub release has already been published.

## Changes

- Adds a Cloud Center room with Cloudflare, AWS and GCP consoles, a cross-cloud cost board and return navigation. Active keyboard, gamepad and touch interactions open native Flutter panels.
- Adds a self-hosted Elixir/Phoenix backend with PostgreSQL snapshots, bounded collection jobs, pagination and read-only provider adapters. Cloud credentials remain on the server; Flutter stores only its application access token.
- Adds explicit Demo mode, bounded isolated offline caches, source timestamps, resource/usage views and application-only budget thresholds. Real-mode failures never substitute Demo amounts.
- Preserves currency, cost-basis, billing-scope and source-window boundaries. Incomplete budget coverage remains unknown; same-ID scene projections update without replacing game state.
- Handles concurrent snapshot revisions, session/logout races, failed query reloads and reverse-order usage responses. Enables backend networking through the macOS sandbox entitlement and Android main Internet permission.

## Provider coverage

- **Cloudflare:** metered Billable Usage, bounded Zones/Workers/R2 default-jurisdiction inventory and configured GraphQL metrics. Fixed subscription fees and other R2 jurisdictions are not covered.
- **AWS:** Cost Explorer service/account costs, documented inventory and CloudWatch metrics. Aggregate costs are not allocated to individual resources; cost bases remain separate.
- **GCP:** requires a configured billing export and bounded BigQuery query permissions. Credits/refunds, invoice month and account-unallocated charges are retained, with documented Compute/Storage/Run inventory and metrics.

Resource and metric support is limited to configured, documented scopes. Unsupported service costs remain visible. No currency conversion, prediction, cloud management, external budget notifications or complete resource-level cost allocation is included.

## Recorded verification

- Root affected Flutter tests: 60 passed; native-panel widget tests: 20 passed; Cloud Center bloc tests: 4 passed.
- New backend: 88 tests, 0 failures, 6 opt-in live tests skipped (82 passed); localhost recovery and Elixir→Dart contract smoke checks passed.
- Scoped client analysis found no issues. The final macOS Debug build succeeded.

See the [validation report](validation-report.md) for the AC01–22 matrix, logs and repair history. These are offline/localhost and build results, not real-provider certification or hosted CI results.

## Known validation limits

All Cloudflare/AWS/GCP accounts remain unverified; no cloud credential was discovered or used. Native Demo checks were partial on an earlier build: CF/AWS panels, input lock and Overview Escape→movement restoration were observed. GCP, the board and complete return-room flow remain unchecked manually. Resource-search Escape passes its widget regression, while native resource-field Escape/X-close observations were inconclusive due to Computer Use window availability. The latest Debug build has not been manually checked.

No iOS/Android build, physical-device test, standalone Release launch, signed binary or store delivery is established. Xcode emitted a CoreSimulator version warning during the successful macOS build; this provides no iOS simulator evidence. There is no hosted CI success to report.

## Setup

Start with [backend deployment](backend-deployment.md) and [provider setup](provider-setup.md), then follow the [Cloudflare](cloudflare-setup.md), [AWS](aws-setup.md) or [GCP](gcp-setup.md) account guide. Configure a backend application token in Flutter; keep provider credentials on the server. Explicitly select Demo when live credentials are unavailable.
