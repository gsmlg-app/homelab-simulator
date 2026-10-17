# Cloud Monitor 后端部署与离线验证

Cloud Center 使用 `services/cloud_monitor/` 中的独立 Phoenix API-only 服务和 PostgreSQL。客户端面板只读取这个服务的持久化结果；客户端关闭、角色注销、离开房间都不会停止部署在服务器上的采集。单用户、单采集实例部署是本阶段的边界。

## 环境与启动

本次离线验证环境：Elixir 1.19 / OTP 28，Phoenix 1.8.15、Ecto 3.13.6、Postgrex 0.22.4（实际依赖由 `mix.lock` 固定），本机 PostgreSQL 18.6。无需 Docker。开发配置连接 `/tmp` Unix socket、端口 5432、当前操作系统用户；数据库分别为 `homelab_cloud_monitor_dev` 和 `homelab_cloud_monitor_test`。

```sh
cd services/cloud_monitor
mix deps.get
mix ecto.setup
MIX_ENV=test mix test
```

部署时使用独立 PostgreSQL 数据库和仅有该数据库访问权的数据库角色；`DATABASE_URL` 指向部署数据库。以下命令中的变量应由服务管理器或受限环境文件提供，而不是提交到版本库：

```sh
export MIX_ENV=prod
export DATABASE_URL='ecto://cloud_monitor:REPLACE@127.0.0.1/cloud_monitor'
export CLOUD_MONITOR_TOKEN='REPLACE_WITH_A_RANDOM_APPLICATION_TOKEN_AT_LEAST_32_CHARACTERS'
export SECRET_KEY_BASE="$(mix phx.gen.secret)"
export CLOUD_MONITOR_CONFIG='/etc/cloud-monitor/connections.json'
export CLOUD_MONITOR_SCHEDULER=true
export PHX_SERVER=true
export PORT=4100
mix deps.get --only prod
mix compile --warnings-as-errors
mix ecto.create
mix ecto.migrate
mix phx.server
```

迁移应先于服务启动。生产运行请通过 systemd、launchd 或等价服务管理器保持进程存活并设置失败重启。不要同时启动第二个采集实例：启动恢复逻辑会把遗留 `running` 作业重新排队，当前版本不提供多节点抢占租约。

HTTP 仅监听 `127.0.0.1`，由同机反向代理提供 HTTPS。客户端远程地址必须是 HTTPS；仅显式本机开发允许 HTTP。Bearer token 是应用令牌，不是云厂商令牌；所有 `/v1` 路由都要求它，少于 16 字符的 token 无法通过认证。生产环境应使用至少 32 字符的随机值，并把 `SECRET_KEY_BASE` 保持为稳定的独立随机值，以维持分页游标签名。

## 连接和凭据引用

`CLOUD_MONITOR_CONFIG` 是 JSON 文件，包含 `connections` 和 `scopes` 两个数组。以下只说明框架字段；具体厂商权限、credential 内容和 settings 请参阅 [provider-setup.md](provider-setup.md)。示例中的占位符必须按真实账号替换。

```json
{
  "connections": [{
    "id": "aws-main",
    "provider": "aws",
    "displayName": "AWS production",
    "billingScopeId": "aws-payer",
    "credentialRef": "file:/etc/cloud-monitor/secrets/aws.json",
    "settings": {
      "usageEnabled": false,
      "intervalSeconds": {"resources": 1800, "usage": 900, "costs": 86400}
    }
  }],
  "scopes": [{
    "id": "aws-payer",
    "provider": "aws",
    "accountId": "REPLACE_ACCOUNT_ID",
    "parentId": null,
    "authoritativeConnectionId": "aws-main"
  }]
}
```

支持 `env:EXACT_VARIABLE_NAME` 或 `file:/absolute/path`。凭据文件限制 64 KiB；将其权限限制为服务用户可读。数据库仅保存引用，不保存读取到的凭据；公共连接 API 不返回引用、settings 或凭据。多个连接读取同一付款范围时，`authoritativeConnectionId` 选择唯一权威来源；子账号用 `parentId` 表达父子关系，不以连接显示名称作为身份。

连接文件中删除一个展示配置不会自动删除已持久化的配置或财务历史。重新部署也不会重置已有预算或快照。停用现有连接的自动采集时，保留其 ID 并把 `credentialRef` 明确设置为 `null`。真正清理历史使用下面的保留策略，不能通过删除游戏对象触发。

CC-05 的 Cloudflare、AWS、GCP 模块通过 `:cloud_monitor, :adapters` 注册，遵循 `CloudMonitor.Adapter.collect/4`。只有明确配置的连接及凭据引用才会触发相应采集；缺少配置返回状态错误，不会返回演示金额。各模块的离线实现验收和真实账号验证状态见 [provider setup](provider-setup.md)。框架通过不表示任何厂商真实账号已验证。

## 采集、重试与持久化

- 默认并发 3、单次任务超时 120 秒、最多 3 次尝试；每个“连接 + 数据集”最多一个 queued/running/retry 作业，数据库唯一索引与事务共同保证。
- 资源默认每 30 分钟；显式启用的指标每 15 分钟；AWS/Cloudflare 费用每日、GCP 费用每 6 小时。`intervalSeconds` 可分别覆盖，最短 60 秒。指标必须显式设置 `usageEnabled`。
- 默认手动刷新冷却 60 秒。资源清单、费用、用量各自持久化状态，失败不清空其他数据集。401/权限/配置错误不密集重试；可重试故障采用有限退避并遵守秒数形式的 Retry-After，最长等待一天。
- 请求预算默认 100 页/100 次；资源上限 1,000，单快照记录上限 10,000。适配器需在所有分页成功后才返回记录；发布事务替换整份范围快照和 revision，不累加前次同步。
- 默认费用查询窗口为本月和前两个月，历史请求最多 93 天；可通过同步 API 的 start/end 分批重读更早的周期。默认窗口会重读本期与上期以接收调整。
- 快照最多保留每连接、每数据集 36 个窗口，时间保留 1,100 天；终态作业保留 30 天。保留值在 `config/config.exs` 中配置，由调度器执行清理。先按实际保留要求修改部署配置并备份数据库。
- `lastAttemptAt`、`lastSuccessAt`、`sourceAsOf` 和实际观测区间分开存储。未知来源 watermark 允许 null；刷新成功不会自行制造来源时间或完整性。

成本使用 PostgreSQL numeric / Decimal，HTTP 金额为十进制字符串。持久化的区间统一 UTC 微秒精度，等价秒/毫秒/微秒表示使用同一个快照键。原生费用桶先按权威连接和父子覆盖选择，再汇总到显式查询窗口：不相交父子日桶可以相加；完全包含的父范围替代子范围；无法分摊的原生周期或父子部分重叠放入 `unmappedTotals`，后者标注 `ambiguousScopeOverlap`。币种和费用口径始终分组，不做汇率换算。

查询游标绑定查询参数和 revision，后续 revision 变化返回 409 `revisionExpired`。每个 GET 响应在单个 PostgreSQL repeatable-read 事务内读取记录、状态和 revision；分页与多表总览共用该快照。revision 同时涵盖公开连接/状态、范围、预算与任务元数据，不含凭据或私有设置；无关公开元数据变化也可能保守地使游标失效，客户端必须重新拉取。两个独立数据库连接的受控并发发布测试已覆盖分页、单连接总览及跨云总览，结果见验证报告。

## 本地 HTTP、数据库重连与服务重启 smoke

这个脚本使用明确标识的离线 fixture，在开发数据库保留 `cc04-local-smoke` 配置、快照和预算；不读取或调用真实云凭据。它拒绝非开发/测试数据库、启动时已启用的调度器或已加载的厂商配置。只在专用开发数据库执行。

```sh
cd services/cloud_monitor
mix ecto.setup
env -u CLOUD_MONITOR_CONFIG -u DATABASE_URL \
  CLOUD_MONITOR_SCHEDULER=false \
  CLOUD_MONITOR_TOKEN=offline-local-smoke-token \
  PHX_SERVER=true PORT=4194 \
  mix run scripts/local_smoke.exs
```

脚本通过实际 loopback HTTP 验证认证、费用查询、带斜杠资源 ID 的用量查询及作业状态；断开并重新连接 PostgreSQL 连接池；停止并重新启动整个 Cloud Monitor 应用，检查配置、费用、预算及中断作业恢复。它没有重启共享的 PostgreSQL 服务，也没有证明云厂商授权可用。脚本结束会停止自己启动的 Cloud Monitor 应用，PostgreSQL 保持运行。

2026-10-17 实际执行记录：

| 检查 | 结果 |
|---|---|
| 继承失败复现 `mix test` | 14 tests，8 failures，全部为 `utc_datetime_usec` 精度不匹配 |
| Astra 修复轮次 1 `mix test` | 17 tests，0 failures；时间精度、同一窗口替换、月预算日桶 |
| 扩展可靠性 `mix test` | 20 tests，0 failures；有界并发、超时保留快照、编码资源 ID |
| 父子窗口回归红测 | 7 tests，2 failures；不相交日桶和部分重叠 |
| Astra 修复轮次 2 `mix test` | 24 tests，0 failures；四种查询窗口父子覆盖场景及共享 fixture parity |
| 本地 smoke | 10 个断言通过；实际 HTTP（含编码斜杠）、数据库连接池重连、应用停止/启动恢复；无云账号验证 |
| `mix format --check-formatted` | exit 0 |
| `MIX_ENV=test mix compile --warnings-as-errors` | exit 0 |

临时命令输出位于 `/tmp/cc04-astra-round1.log`、`/tmp/cc04-reliability-tests.log`、`/tmp/cc04-overlap-red.log`、`/tmp/cc04-astra-round2.log`、`/tmp/cc04-local-smoke-final.log`。这些是本次机器上的证据路径，不作为部署依赖。

真实 Cloudflare、AWS、GCP 验证状态均为“待显式配置凭据和必要权限”。真实只读适配器及各厂商 live smoke 由 CC-05 验收；不能将本地 fixture 成功写为真实云验证。缺少真实验证时只允许注明限制的 prerelease，发布还必须满足整体集成与 CI 条件。

## Actual backend → Dart contract smoke (offline)

From `services/cloud_monitor`, with the isolated development database migrated:

```sh
CLOUD_MONITOR_SCHEDULER=false \
CLOUD_MONITOR_TOKEN=offline-contract-token \
PHX_SERVER=true PORT=4195 \
mix run scripts/client_contract_smoke.exs
```

This launcher refuses configured providers, an enabled scheduler, or a non-development database. It seeds explicitly named `client-contract` synthetic data, starts the actual Phoenix HTTP boundary, and launches `tool/cloud_center_backend_smoke.dart` through the real Dart repository. It validates distinct cost bases, adjustments, pagination/revision, encoded resource usage, application budget writes, and durable sync jobs. It neither reads provider credentials nor calls provider APIs. Synthetic rows remain only in the isolated development database. The example application token is disposable local test data; use a separate secret for deployments.
