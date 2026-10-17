# AWS read-only adapter

Status: real HTTP implementation and offline contract tests are available. **Real AWS account verification remains pending explicit configuration.** Offline fixtures and localhost transport checks do not prove IAM access or real billing coverage.

The backend adapter is `CloudMonitor.Adapters.AWS`. It uses `aws_signature` 0.4.3 for SigV4, including the optional session token, and verifies the configured account with regional STS `GetCallerIdentity`. No SDK credential discovery, home-directory scanning, browser scraping, paid metric enablement or cloud mutation occurs.

## Server configuration

Add a connection and matching BillingScope to the backend configuration described in `backend-deployment.md`. Use separate connections/credential references for different AWS identities. The connection's resource account is distinct from the linked accounts included in the payer's Cost Explorer view.

```json
{
  "id": "aws-production",
  "provider": "aws",
  "displayName": "AWS production",
  "billingScopeId": "aws-payer-scope",
  "credentialRef": "file:/run/secrets/aws-readonly.json",
  "settings": {
    "accountId": "123456789012",
    "linkedAccountIds": ["123456789012", "210987654321"],
    "regions": ["us-east-1", "eu-west-1"],
    "usageEnabled": true,
    "metricsWindowDays": 7,
    "metricResources": [
      {"service": "EC2", "id": "i-0123456789abcdef0", "region": "us-east-1"},
      {"service": "EBS", "id": "vol-0123456789abcdef0", "region": "us-east-1"},
      {"service": "S3", "id": "my-bucket", "region": "eu-west-1", "storageTypes": ["StandardStorage", "StandardIAStorage"]}
    ]
  }
}
```

The explicitly referenced file, or environment variable via `env:EXPLICIT_AWS_CREDENTIAL_JSON`, contains only the operator-provided credential JSON:

```json
{
  "accessKeyId": "<read-only access key>",
  "secretAccessKey": "<secret access key>",
  "sessionToken": "<temporary-session token when applicable>",
  "expiration": "2026-10-18T00:00:00Z"
}
```

`sessionToken` and `expiration` are optional; omit unused keys. Rotate temporary credentials by updating the mounted secret/reference externally. The adapter reads that exact reference for each collection; it does not assume roles or refresh credentials itself. Never commit the file, put credentials in Flutter, or include them in support logs.

Only explicitly listed commercial AWS regions are supported here. China and GovCloud partitions require distinct endpoints/billing availability and are rejected rather than silently routed to commercial endpoints. A connection inventories only its verified credential account; linked Cost Explorer accounts are not assumed-role inventory targets. Configure additional connections for those resource accounts, and set scope authority/parent relationships to prevent payer and child totals being added twice.

## Minimum read permissions and prerequisites

Use a dedicated read-only role/session with the following actions. Some AWS list/metrics/billing APIs require `Resource: "*"`; apply identity boundaries and linked-account filters where AWS supports them.

- `ce:GetCostAndUsage`, with Cost Explorer enabled and authorized for the payer/member billing view. Cost Explorer API queries can incur AWS charges; all callers share backend snapshots and collection jobs rather than triggering per-panel cloud requests.
- `ec2:DescribeInstances`, `ec2:DescribeVolumes` in configured regions.
- `s3:ListAllMyBuckets`; the adapter uses paginated `ListBuckets` with `bucket-region` at the matching regional S3 endpoint. No object contents, bucket writes or bucket-tag read permissions are needed.
- `cloudwatch:GetMetricData` for configured metric resources. It uses existing EC2/EBS and S3 daily storage metrics; it never calls `PutBucketMetricsConfiguration` or enables paid S3 request metrics.
- STS `GetCallerIdentity` establishes the account identity. AWS documents that this operation requires no explicit allow; organizational/network restrictions can still prevent the request.

## Data semantics and limits

Cost Explorer uses `GetCostAndUsage` in `us-east-1`, `Granularity: DAILY`, `Metrics: [UnblendedCost]` and exactly `SERVICE` plus `LINKED_ACCOUNT` grouping. Linked accounts are filtered explicitly. All returned services, signed decimal amounts and `Estimated` flags are retained, including negative corrections. Amounts remain source decimal strings. A stable cost ID does not include its amount, so a changed historical charge replaces its prior snapshot record.

This view includes the source's service/account aggregate; category is `unknown` because adding a third record-type grouping would violate the two-dimension API limit. Credits/refunds must not be inferred from a negative sign alone. This adapter does not claim itemized tax/credit/refund classification or resource-level allocation. `resourceId` remains null. No `UsageQuantity` is summed across incompatible usage types/units.

Cost Explorer does not provide a completeness watermark here: `sourceAsOf` stays null, successful nonempty costs are marked partial, and ambiguous empty costs or metrics return a waiting error rather than publishing empty snapshots. The backend retains prior rows and source timestamps while recording the new waiting state and attempt time; empty results do not prove zero spend or zero usage. Confirmed empty resource inventories still publish as empty. Native daily intervals are UTC `[start,end)`; CE requests must use UTC midnight boundaries. The backend rereads current/prior periods so later adjustments replace cached history. The overview/budget layer aggregates only compatible contained daily buckets.

Inventories cover EC2 instances, EBS volumes and S3 buckets in configured regions, with stable account/region/type/source IDs. This is not an all-AWS-resource count. EC2/S3 pagination must finish completely; malformed pages, permission failures, cycles and configured limits return errors without publishing partial snapshots. Missing one inventory permission fails that inventory dataset while costs remain independent.

CloudWatch uses `GetMetricData`, not cost-derived usage:

| Service | Metrics | Aggregation / native units | Interval |
|---|---|---|---|
| EC2 | CPUUtilization, NetworkIn, NetworkOut | Average Percent; Sum Bytes | 5 minutes |
| EBS | VolumeReadOps/WriteOps, VolumeReadBytes/WriteBytes | Sum Count or Bytes | 5 minutes |
| S3 | BucketSizeBytes per configured StorageType; NumberOfObjects AllStorageTypes | Average Bytes or Count | 1 day |

Storage type is retained in the metric series label, preventing unrelated storage series being treated as repeated totals. CloudWatch numeric values originate as doubles; decimal text normalization cannot recover upstream precision. Missing metrics remain waiting/partial and are never replaced by zero. Samples outside the requested full bucket interval are not prorated. `sourceAsOf` remains unknown even when samples exist.

Limits are per collection across all regional requests, including STS: default 100 HTTP requests, 100 pages per individual operation, 1,000 inventory/configured metric resources and 10,000 records. Backend options can lower these limits. At most 20 explicit regions and 100 explicit linked accounts are accepted. Runtime metric history defaults to 7 days and is capped at 14; no discovery of arbitrary resources or regions occurs. S3 daily metrics may lag and require a sufficiently broad query window.

## Offline and live validation

From `services/cloud_monitor`:

```sh
mix test test/cloud_monitor/aws
mix format --check-formatted lib/cloud_monitor/adapters/aws.ex lib/cloud_monitor/adapters/aws/*.ex test/cloud_monitor/aws/*.exs scripts/aws_live_smoke.exs
mix compile --warnings-as-errors
```

Offline checks cover actual local TCP transport of signed STS/CE requests, deterministic SigV4 canonical signing, pagination, errors, unknown services, historical adjustments, XML structure, scope limits and metric units. Jobs/Store integration regressions verify that ambiguous empty costs and metrics retain existing rows, snapshot revisions and source timestamps while updating the waiting state and attempt time. They use intentionally fake public/example credentials and never contact AWS.

For live verification, create an untracked JSON file containing `connection` (the server connection above), optionally `datasets` (`costs`, `resources`, `usage`), UTC-midnight `start`/`end`, `requestBudget` (default 20) and `maxResources`. Default live range is the preceding three UTC days; requesting costs may incur AWS API charges. Configure `metricResources` for usage first. Then explicitly run:

```sh
CLOUD_MONITOR_AWS_LIVE=1 \
CLOUD_MONITOR_AWS_LIVE_CONFIG=/absolute/private/aws-live-config.json \
mix run --no-start scripts/aws_live_smoke.exs
```

The script does not start the backend scheduler or require PostgreSQL, prints only dataset counts and sanitized status, and exits nonzero on any failed dataset. Without `CLOUD_MONITOR_AWS_LIVE=1` it exits before reading the live config/credential reference or sending HTTP requests. A successful cost request still reports unknown completeness and must not be recorded as proof of a final invoice.

## Protocol inspection

Official SDK service-model shapes were inspected on 2026-10-17 for Cost Explorer request/result fields and signing target, S3 paginated regional ListBuckets, and CloudWatch GetMetricData query request/result fields. The AWS documentation host returned timeouts/503 in this environment, so the reference links below were not live-verified. Protocol inspection does not replace real-account validation.

- [GetCostAndUsage](https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_GetCostAndUsage.html), [official SDK model](https://github.com/boto/botocore/blob/develop/botocore/data/ce/2017-10-25/service-2.json)
- [EC2 DescribeInstances](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html), [DescribeVolumes](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeVolumes.html)
- [S3 ListBuckets](https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html), [official SDK model](https://github.com/boto/botocore/blob/develop/botocore/data/s3/2006-03-01/service-2.json)
- [GetMetricData](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_GetMetricData.html), [official SDK model](https://github.com/boto/botocore/blob/develop/botocore/data/cloudwatch/2010-08-01/service-2.json)
- [S3 CloudWatch dimensions](https://docs.aws.amazon.com/AmazonS3/latest/userguide/metrics-dimensions.html)
- [aws_signature v0.4.3](https://github.com/aws-beam/aws_signature/tree/v0.4.3)
