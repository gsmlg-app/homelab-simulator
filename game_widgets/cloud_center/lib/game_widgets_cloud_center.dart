import 'package:app_cloud/app_cloud.dart';
import 'package:app_bloc_cloud_center/app_bloc_cloud_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Native, modal cloud cache viewer. The host owns scene input gating.
class CloudCenterPanel extends StatefulWidget {
  final CloudCenterCubit cubit;
  final CloudMode mode;
  final VoidCallback onClose;
  final VoidCallback onConfigure;
  const CloudCenterPanel({
    super.key,
    required this.cubit,
    required this.mode,
    required this.onClose,
    required this.onConfigure,
  });
  @override
  State<CloudCenterPanel> createState() => _CloudCenterPanelState();
}

class _CloudCenterPanelState extends State<CloudCenterPanel> {
  int _tab = 0;
  final _search = TextEditingController();
  final _service = TextEditingController();
  final _region = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    _service.dispose();
    _region.dispose();
    super.dispose();
  }

  CloudCenterCubit get cubit => widget.cubit;
  String time(DateTime? value) =>
      value == null ? 'Unknown' : '${value.toUtc().toIso8601String()} (UTC)';
  Widget field(String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.labelSmall),
        SelectableText(value),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
    },
    child: Focus(
      autofocus: true,
      child: Stack(
        children: [
          const Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Colors.black54),
          ),
          LayoutBuilder(
            builder: (context, constraints) => Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                key: const Key('cloud-center-panel'),
                width: constraints.maxWidth < 800 ? constraints.maxWidth : 580,
                height: constraints.maxHeight,
                child: Material(
                  elevation: 16,
                  color: Theme.of(context).colorScheme.surface,
                  child: SafeArea(
                    child: BlocBuilder<CloudCenterCubit, CloudCenterState>(
                      bloc: cubit,
                      builder: (context, state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    state.provider == null
                                        ? 'Cloud Center · All providers'
                                        : 'Cloud Center · ${state.provider!.name.toUpperCase()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Configure backend',
                                  onPressed: widget.onConfigure,
                                  icon: const Icon(Icons.settings),
                                ),
                                IconButton(
                                  tooltip: 'Close cloud panel',
                                  onPressed: widget.onClose,
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              widget.mode == CloudMode.demo
                                  ? 'DEMO · Synthetic data'
                                  : 'REAL · Self-hosted backend cache',
                              style: TextStyle(
                                color: widget.mode == CloudMode.demo
                                    ? Colors.amber
                                    : Colors.lightBlue,
                              ),
                            ),
                          ),
                          if (state.offline)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Offline cache · Source times below are unchanged',
                              ),
                            ),
                          if (state.connections.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: state.selectedId,
                                hint: const Text('Cross-cloud overview'),
                                items: [
                                  if (state.provider == null)
                                    const DropdownMenuItem(
                                      value: '',
                                      child: Text(
                                        'All connections · Separate currencies',
                                      ),
                                    ),
                                  ...state.connections.map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(
                                        c.displayName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (id) {
                                  if (id == '') {
                                    cubit.open();
                                  } else if (id != null) {
                                    cubit.selectConnection(id);
                                  }
                                },
                              ),
                            ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(
                                6,
                                (index) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(
                                      const [
                                        'Overview',
                                        'Costs',
                                        'Resources',
                                        'Usage',
                                        'Connection',
                                        'Budgets',
                                      ][index],
                                    ),
                                    selected: _tab == index,
                                    onSelected: (_) =>
                                        setState(() => _tab = index),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (state.loading) const LinearProgressIndicator(),
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '${state.error!.code}: ${state.error!.message}',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: _content(state),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Cached snapshots · ${state.syncJob?.state ?? 'No sync requested'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: state.loading
                                      ? null
                                      : () => cubit.reload(),
                                  icon: const Icon(Icons.download),
                                  label: const Text('Reload cache'),
                                ),
                                IconButton(
                                  tooltip: 'Request collection',
                                  onPressed: state.loading
                                      ? null
                                      : () => cubit.refresh(
                                          dataset: _tab == 2
                                              ? 'resources'
                                              : _tab == 3
                                              ? 'usage'
                                              : 'costs',
                                        ),
                                  icon: const Icon(Icons.sync),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _content(CloudCenterState s) => switch (_tab) {
    0 => _overview(s),
    1 => _costs(s),
    2 => _resources(s),
    3 => _usage(s),
    4 => _connection(s),
    _ => _budgets(s),
  };
  List<Widget> _overview(CloudCenterState s) {
    final totals = s.connectionOverview?.totals ?? s.overview?.totals ?? [];
    final unmapped =
        s.connectionOverview?.unmappedTotals ??
        s.overview?.unmappedTotals ??
        [];
    return [
      field(
        'Comparison window',
        '${time(cubit.query.start)} → ${time(cubit.query.end)} · end exclusive',
      ),
      const Text(
        'Currency, cost basis and native windows remain separate. Unknown data is not zero.',
      ),
      if (totals.isEmpty)
        const ListTile(
          title: Text('No reported comparable costs'),
          subtitle: Text(
            'Check connection status and scope; this does not imply zero spend.',
          ),
        ),
      ...totals.map(
        (t) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.currency} ${t.amount}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(t.basis),
                Text('${time(t.start)} → ${time(t.end)}'),
              ],
            ),
          ),
        ),
      ),
      ...unmapped.map(
        (t) => ListTile(
          title: Text('${t.currency} ${t.amount} · Excluded from comparison'),
          subtitle: Text(
            'Native interval: ${time(t.start)} → ${time(t.end)} · ${t.basis}',
          ),
        ),
      ),
      if (s.connectionOverview != null)
        field(
          'Supported resource inventory',
          '${s.connectionOverview!.resourceCount} · limited to configured supported services',
        ),
      ...?s.overview?.coverage.map((c) => field('Coverage', c)),
      ..._connection(s),
    ];
  }

  List<Widget> _connection(CloudCenterState s) => [
    if (s.connections.isEmpty)
      ListTile(
        title: const Text('No backend connection'),
        subtitle: const Text(
          'Configure a real backend or explicitly choose Demo.',
        ),
        trailing: IconButton(
          onPressed: widget.onConfigure,
          icon: const Icon(Icons.settings),
        ),
      ),
    ...s.connections
        .where((c) => s.selectedId == null || c.id == s.selectedId)
        .expand(
          (c) => [
            Text(
              '${c.displayName} · ${c.billingScopeId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...c.capabilities.entries.map(
              (e) => field('${e.key} capability', e.value),
            ),
            ...c.statuses.entries.map(
              (entry) => ExpansionTile(
                initiallyExpanded: true,
                title: Text('${entry.key} · ${entry.value.state.name}'),
                subtitle: Text(
                  entry.value.complete
                      ? 'Source scope complete'
                      : 'Incomplete or unknown coverage',
                ),
                children: [
                  field('Last attempt', time(entry.value.lastAttemptAt)),
                  field(
                    'Last collection success',
                    time(entry.value.lastSuccessAt),
                  ),
                  field('Source updated', time(entry.value.sourceAsOf)),
                  field(
                    'Observed interval',
                    '${time(entry.value.observedStart)} → ${time(entry.value.observedEnd)}',
                  ),
                  if (entry.value.reason != null)
                    field('Coverage / reason', entry.value.reason!),
                ],
              ),
            ),
          ],
        ),
  ];

  List<Widget> _costs(CloudCenterState s) {
    final groups = <String, DecimalAmount>{};
    final trends = <String, DecimalAmount>{};
    final uniqueRows = {
      for (final r in s.costs) '${r.billingScopeId}:${r.id}': r,
    };
    for (final r in uniqueRows.values.where((r) => r.view == CostView.period)) {
      final key =
          '${r.billingScopeId} · ${r.service} · ${r.currency} · ${r.basis} · ${time(r.start)} → ${time(r.end)}';
      groups[key] = (groups[key] ?? DecimalAmount.zero) + r.amount;
      final day =
          '${time(r.start)} → ${time(r.end)} · ${r.billingScopeId} · ${r.currency} · ${r.basis}';
      trends[day] = (trends[day] ?? DecimalAmount.zero) + r.amount;
    }
    final sortedTrends = trends.keys.toList()..sort();
    return [
      OutlinedButton.icon(
        onPressed: _pickDates,
        icon: const Icon(Icons.date_range),
        label: const Text('Choose date range (maximum 93 days)'),
      ),
      field(
        'Window (UTC, end exclusive)',
        '${time(cubit.query.start)} → ${time(cubit.query.end)}',
      ),
      const Text(
        'Reported period costs · No forecast · Unlinked resource costs remain unallocated.',
      ),
      if (s.nextCostCursor != null)
        const Text(
          'Partial list: load remaining pages before interpreting subtotals.',
        ),
      const ListTile(title: Text('Cost trend · native intervals')),
      ...sortedTrends.map(
        (key) =>
            ListTile(title: Text(trends[key].toString()), subtitle: Text(key)),
      ),
      const ListTile(title: Text('Service breakdown')),
      ...groups.entries.map(
        (e) => ListTile(title: Text(e.value.toString()), subtitle: Text(e.key)),
      ),
      ...s.costs.map(
        (r) => ExpansionTile(
          title: Text('${r.service} · ${r.currency} ${r.amount}'),
          subtitle: Text(
            '${r.category.name} · ${r.view.name} · ${r.estimated == true ? 'Estimated' : 'Reported; finality not guaranteed'}',
          ),
          children: [
            field('Source / precision', '${r.source} · ${r.sourcePrecision}'),
            field('Basis', r.basis),
            field('Resource attribution', r.resourceId ?? 'Unallocated'),
            field('Native interval', '${time(r.start)} → ${time(r.end)}'),
            field('Invoice month', r.invoiceMonth ?? 'Unknown'),
            ...r.coverage.map((c) => field('Coverage', c)),
          ],
        ),
      ),
      if (s.costs.isEmpty) const Text('No cost rows available for this query.'),
      if (s.nextCostCursor != null)
        OutlinedButton(
          onPressed: s.loading ? null : cubit.loadMoreCosts,
          child: const Text('Load next cost page'),
        ),
    ];
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 370)),
    );
    if (range == null || !mounted) return;
    final start = DateTime.utc(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime.utc(
      range.end.year,
      range.end.month,
      range.end.day + 1,
    );
    if (end.difference(start) > const Duration(days: 93)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose at most 93 days')));
      return;
    }
    await cubit.reload(
      newQuery: CloudQuery(start: start, end: end),
    );
  }

  List<Widget> _resources(CloudCenterState s) => [
    TextField(
      controller: _search,
      decoration: const InputDecoration(labelText: 'Search resources'),
      onSubmitted: (_) => _filter(),
    ),
    TextField(
      controller: _service,
      decoration: const InputDecoration(labelText: 'Service filter'),
      onSubmitted: (_) => _filter(),
    ),
    TextField(
      controller: _region,
      decoration: const InputDecoration(labelText: 'Region filter'),
      onSubmitted: (_) => _filter(),
    ),
    TextButton(onPressed: _filter, child: const Text('Apply filters')),
    const Text(
      'Only supported resource types; inventory coverage differs from billing coverage.',
    ),
    ...s.resources.map(
      (r) => ExpansionTile(
        key: ValueKey(r.id),
        title: Text(r.name),
        subtitle: Text('${r.service} · ${r.type} · ${r.region}'),
        children: [
          field('Stable identity', r.id),
          field('Runtime state', r.state ?? 'Unknown'),
          field('Observed at', time(r.observedAt)),
          field('Labels', r.tags.toString()),
          TextButton(
            onPressed: () {
              cubit.loadUsage(r.id);
              setState(() => _tab = 3);
            },
            child: const Text('View usage'),
          ),
        ],
      ),
    ),
    if (s.resources.isEmpty)
      const Text('No resource rows for this query; check source capability.'),
    if (s.nextResourceCursor != null)
      OutlinedButton(
        onPressed: s.loading ? null : cubit.loadMoreResources,
        child: const Text('Load next resource page'),
      ),
  ];
  void _filter() => cubit.reload(
    newQuery: CloudQuery(
      start: cubit.query.start,
      end: cubit.query.end,
      search: _search.text.isEmpty ? null : _search.text,
      service: _service.text.isEmpty ? null : _service.text,
      region: _region.text.isEmpty ? null : _region.text,
    ),
  );
  List<Widget> _usage(CloudCenterState s) => [
    const Text(
      'Select a resource to view bounded source metrics. Usage does not imply cost or resource health.',
    ),
    ...s.usage.map(
      (u) => ListTile(
        title: Text('${u.metric}: ${u.value} ${u.unit}'),
        subtitle: Text(
          '${u.service} · ${u.aggregation} · ${u.granularity}\n${time(u.start)} → ${time(u.end)}\nSource: ${u.source}',
        ),
      ),
    ),
    if (s.usage.isEmpty)
      const Text(
        'No usage samples selected or available. Check metric permissions and configured coverage.',
      ),
  ];
  List<Widget> _budgets(CloudCenterState s) {
    final connection = s.selectedConnection;
    return [
      const Text(
        'Application budgets only · No cloud resource or provider budget changes.',
      ),
      if (connection != null)
        OutlinedButton(
          onPressed: () => _editBudget(connection),
          child: const Text('Add budget for this scope / window'),
        ),
      ...s.budgets
          .where(
            (r) =>
                connection == null ||
                r.billingScopeId == connection.billingScopeId,
          )
          .map((rule) {
            final relevant = s.connections
                .where((c) => c.billingScopeId == rule.billingScopeId)
                .toList();
            final scopes = relevant.map(
              (c) => BillingScope(
                id: c.billingScopeId,
                provider: c.provider,
                accountId: c.billingScopeId,
                authoritativeConnectionId: c.id,
              ),
            );
            final result = evaluateBudget(
              rule,
              s.costs,
              scopes: scopes,
              complete:
                  !s.loading &&
                  !s.offline &&
                  s.error == null &&
                  s.nextCostCursor == null &&
                  (connection?.statuses['costs']?.complete ?? false) &&
                  cubit.query.service == null &&
                  cubit.query.region == null &&
                  cubit.query.project == null &&
                  cubit.query.search == null &&
                  (cubit.query.basis == null ||
                      cubit.query.basis == rule.basis) &&
                  cubit.query.start != null &&
                  !cubit.query.start!.isAfter(rule.start) &&
                  !cubit.query.end!.isBefore(rule.end),
            );
            return ListTile(
              title: Text(
                '${rule.currency} ${rule.amount} · ${result.state.name}',
              ),
              subtitle: Text(
                '${rule.basis} · Known: ${result.knownAmount}\n${time(rule.start)} → ${time(rule.end)}${result.complete ? '' : '\nPartial coverage: below threshold does not mean safe'}',
              ),
            );
          }),
    ];
  }

  Future<void> _editBudget(CloudConnection connection) async {
    final amount = TextEditingController();
    final currency = TextEditingController(
      text: cubit.state.costs.firstOrNull?.currency ?? 'USD',
    );
    final basis = TextEditingController(
      text: cubit.state.costs.firstOrNull?.basis ?? 'UnblendedCost',
    );
    String? error;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Application budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amount,
                  decoration: const InputDecoration(
                    labelText: 'Decimal amount (zero disables)',
                  ),
                ),
                TextField(
                  controller: currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
                TextField(
                  controller: basis,
                  decoration: const InputDecoration(labelText: 'Cost basis'),
                ),
                if (error != null) Text(error!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                try {
                  if (DecimalAmount.parse(amount.text).isNegative ||
                      currency.text.isEmpty ||
                      basis.text.isEmpty) {
                    throw const FormatException();
                  }
                  Navigator.pop(context, true);
                } on Object {
                  update(
                    () => error = 'Enter a non-negative decimal and explicit currency / basis',
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true && mounted) {
      await cubit.saveBudget(
        BudgetRule(
          id: '${connection.billingScopeId}:${currency.text}:${basis.text}:${cubit.query.start!.toIso8601String()}',
          billingScopeId: connection.billingScopeId,
          currency: currency.text,
          start: cubit.query.start!,
          end: cubit.query.end!,
          basis: basis.text,
          amount: DecimalAmount.parse(amount.text),
          thresholds: [DecimalAmount.parse('0.8'), DecimalAmount.parse('1')],
        ),
      );
    }
    amount.dispose();
    currency.dispose();
    basis.dispose();
  }
}
