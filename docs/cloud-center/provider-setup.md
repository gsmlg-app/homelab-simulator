# Provider setup (initial contract)

Cloud credentials are server deployment inputs only, via environment or read-only secret files. Client stores only the application bearer token in existing secure storage. Three providers remain **live verification pending configuration** until explicit smoke tests succeed.

- Cloudflare: scoped account token for Billable Usage (capability dependent Alpha), Zones read, Workers scripts read, R2 read and account analytics. Usage charges exclude unproven fixed subscription coverage. Preserve native charge periods and separate cumulative/invoice views.
- AWS: read-only Cost Explorer GetCostAndUsage (UnblendedCost, daily SERVICE + LINKED_ACCOUNT); EC2 DescribeInstances/DescribeVolumes; S3 ListAllMyBuckets; CloudWatch GetMetricData. SigV4 with configured region and optional session token. No paid request-metric enablement. Resource-level cost is unallocated unless source explicitly associates it.
- GCP: billing export BigQuery dataset/table configured explicitly; billing account + permitted projects, read-only resource listing and monitoring, bounded BigQuery query jobs. Billing export reader and jobs permission required. Service account or explicit short-lived OAuth configuration is server-side. Base cost must not duplicate when credits are unnested. Preserve invoice and usage month.

Deployment, minimum permissions and explicit opt-in smoke commands are in the provider guides below. No credentials have been searched for or tested.

## Official API inspection evidence (2026-10-17)

Cloudflare's current [Billable Usage reference](https://developers.cloudflare.com/api/resources/billing/subresources/usage/methods/paygo/) was fetched as Markdown. It specifies **GET /accounts/{account_id}/billable-usage**, `from`/`to` date query parameters and a deprecated operation name (`paygo`, replacement `get_account_usage_v1`). It does not specify a POST billing/usage/paygo endpoint. Its example uses `BillingCurrency`, `ServiceName`, `ChargePeriodStart`, `ChargePeriodEnd`, `BillingPeriodStart`, `ContractedCost`, and `CumulatedContractedCost`. Query range must include subscription cycle anchor day; an empty result outside that range cannot imply zero spend. The stable public api-schemas OpenAPI billing/usage endpoint reports usage counters and is not a substitute billing-amount source. Adapter must encapsulate the documented Alpha operation and report capability/coverage failures explicitly.

## Adapter capability and verification matrix

All provider credentials stay on the backend. Flutter's Real mode authenticates only to the self-hosted API. A passing fixture test proves protocol/normalization behavior, not account entitlement or production coverage.

| Provider | Setup and permissions | Implemented scope / limitations | Offline verification | Live account |
| --- | --- | --- | --- | --- |
| Cloudflare | [Cloudflare setup](cloudflare-setup.md) | V1 metered billable usage; native period/cumulative separate; Zones, Workers scripts, default-jurisdiction R2; configured Workers/Zone/R2 GraphQL metrics. Fixed subscriptions and other R2 jurisdictions uncovered. | 17 passed; 3 live tests skipped | Pending explicit configuration |
| AWS | [AWS setup](aws-setup.md) | Signed STS account check; daily service/linked-account CE UnblendedCost; scoped EC2/EBS/S3 and existing CloudWatch metrics. Commercial partitions only; no resource cost allocation or itemized record categories. | 16 passed including waiting-snapshot preservation; gated live probe not run | Pending explicit configuration |
| GCP | [GCP setup](gcp-setup.md) | Bounded parameterized BigQuery export with correlated credits and account-unallocated charges; configured Compute/disks/Storage/Run inventories and descriptor-validated Monitoring. Export completeness always partial; no resource cost allocation. | 18 passed including JWT and persisted waiting retention; 3 live tests skipped | Pending explicit configuration |

For client/backend protocol validation without provider accounts, use the [offline contract smoke](backend-deployment.md#actual-backend--dart-contract-smoke-offline). It deliberately uses synthetic data and an isolated development database, and must not be reported as real cloud validation.
