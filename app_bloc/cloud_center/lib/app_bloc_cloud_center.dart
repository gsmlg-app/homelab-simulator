import 'dart:async';

import 'package:app_cloud/app_cloud.dart';
import 'package:bloc/bloc.dart';

/// UI state is independent of the server's collection lifecycle.
final class CloudCenterState {
  final bool isOpen;
  final bool loading;
  final bool offline;
  final CloudProvider? provider;
  final String? selectedId;
  final List<CloudConnection> connections;
  final CloudOverview? overview;
  final ConnectionOverview? connectionOverview;
  final List<CostRecord> costs;
  final List<CloudResource> resources;
  final List<UsageSample> usage;
  final List<BudgetRule> budgets;
  final String? nextCostCursor;
  final String? nextResourceCursor;
  final String? costRevision;
  final String? resourceRevision;
  final SyncJob? syncJob;
  final CloudFailure? error;
  const CloudCenterState({
    this.isOpen = false,
    this.loading = false,
    this.offline = false,
    this.provider,
    this.selectedId,
    this.connections = const [],
    this.overview,
    this.connectionOverview,
    this.costs = const [],
    this.resources = const [],
    this.usage = const [],
    this.budgets = const [],
    this.nextCostCursor,
    this.nextResourceCursor,
    this.costRevision,
    this.resourceRevision,
    this.syncJob,
    this.error,
  });
  CloudConnection? get selectedConnection {
    for (final c in connections) {
      if (c.id == selectedId) return c;
    }
    return null;
  }

  CloudCenterState copy({
    bool? loading,
    bool? offline,
    List<CloudConnection>? connections,
    CloudOverview? overview,
    ConnectionOverview? connectionOverview,
    List<CostRecord>? costs,
    List<CloudResource>? resources,
    List<UsageSample>? usage,
    List<BudgetRule>? budgets,
    String? nextCostCursor,
    String? nextResourceCursor,
    String? costRevision,
    String? resourceRevision,
    bool costsPage = false,
    bool resourcesPage = false,
    SyncJob? syncJob,
    CloudFailure? error,
    bool clearError = false,
  }) => CloudCenterState(
    isOpen: isOpen,
    provider: provider,
    selectedId: selectedId,
    loading: loading ?? this.loading,
    offline: offline ?? this.offline,
    connections: connections ?? this.connections,
    overview: overview ?? this.overview,
    connectionOverview: connectionOverview ?? this.connectionOverview,
    costs: costs ?? this.costs,
    resources: resources ?? this.resources,
    usage: usage ?? this.usage,
    budgets: budgets ?? this.budgets,
    nextCostCursor: costsPage ? nextCostCursor : this.nextCostCursor,
    nextResourceCursor: resourcesPage
        ? nextResourceCursor
        : this.nextResourceCursor,
    costRevision: costRevision ?? this.costRevision,
    resourceRevision: resourceRevision ?? this.resourceRevision,
    syncJob: syncJob ?? this.syncJob,
    error: clearError ? null : error ?? this.error,
  );
}

class CloudCenterCubit extends Cubit<CloudCenterState> {
  final CloudRepository repository;
  final bool Function()? responseWasCached;
  CloudCancellation? _cancellation;
  CloudCancellation? _usageCancellation;
  int _usageSequence = 0;
  Timer? _poller;
  int _sequence = 0;
  CloudQuery query;
  CloudCenterCubit(
    this.repository, {
    CloudQuery? initialQuery,
    this.responseWasCached,
  }) : query = initialQuery ?? _calendarMonth(),
       super(const CloudCenterState());
  static CloudQuery _calendarMonth() {
    final now = DateTime.now().toUtc();
    return CloudQuery(
      start: DateTime.utc(now.year, now.month),
      end: DateTime.utc(now.year, now.month + 1),
    );
  }

  bool _current(int seq) => !isClosed && state.isOpen && seq == _sequence;
  CloudCancellation _newRequest() {
    _cancellation?.cancel();
    _usageCancellation?.cancel();
    return _cancellation = CloudCancellation();
  }

  CloudFailure _failure(Object error) => error is CloudFailure
      ? error
      : const CloudFailure('invalidResponse', 'Cloud data could not be loaded');

  Future<void> open({CloudProvider? provider, String? connectionId}) async {
    _poller?.cancel();
    final seq = ++_sequence;
    final token = _newRequest();
    emit(
      CloudCenterState(
        isOpen: true,
        loading: true,
        provider: provider,
        selectedId: connectionId,
      ),
    );
    try {
      final page = await repository.connections(cancellation: token);
      if (!_current(seq)) return;
      final options = page.data
          .where((c) => provider == null || c.provider == provider)
          .toList();
      final selected = options.any((c) => c.id == connectionId)
          ? connectionId
          : (provider != null && options.isNotEmpty ? options.first.id : null);
      emit(
        CloudCenterState(
          isOpen: true,
          loading: true,
          provider: provider,
          selectedId: selected,
          connections: List.unmodifiable(options),
          offline: responseWasCached?.call() ?? false,
        ),
      );
      if (provider != null && selected == null) {
        emit(
          state.copy(
            loading: false,
            error: const CloudFailure(
              'unconfigured',
              'No connection configured for this provider',
            ),
          ),
        );
        return;
      }
      await _load(seq, token);
      if (_current(seq)) setForeground(true);
    } on Object catch (e) {
      if (_current(seq)) emit(state.copy(loading: false, error: _failure(e)));
    }
  }

  Future<void> _guard(int seq, Future<void> Function() operation) async {
    try {
      await operation();
    } on Object catch (e) {
      if (_current(seq)) emit(state.copy(error: _failure(e)));
    }
  }

  bool get _cached => state.offline || (responseWasCached?.call() ?? false);
  Future<void> _load(int seq, CloudCancellation token) async {
    final id = state.selectedId;
    // Each dataset failure leaves other previously accepted datasets intact.
    await _guard(seq, () async {
      if (id == null) {
        final data = await repository.overview(query, cancellation: token);
        if (_current(seq)) {
          emit(state.copy(overview: data.data, offline: _cached));
        }
      } else {
        final data = await repository.connectionOverview(
          id,
          query,
          cancellation: token,
        );
        if (_current(seq)) {
          emit(
            state.copy(
              connectionOverview: data.data,
              connections: List.unmodifiable(
                state.connections.map(
                  (connection) => connection.id == data.data.connection.id
                      ? data.data.connection
                      : connection,
                ),
              ),
              offline: _cached,
            ),
          );
        }
      }
    });
    if (!_current(seq)) return;
    if (id != null) {
      await _guard(seq, () async {
        final page = await repository.costs(id, _query(), cancellation: token);
        if (_current(seq)) {
          emit(
            state.copy(
              costs: page.data,
              nextCostCursor: page.nextCursor,
              costRevision: page.revision,
              costsPage: true,
              offline: _cached,
            ),
          );
        }
      });
      if (!_current(seq)) return;
      await _guard(seq, () async {
        final page = await repository.resources(
          id,
          _query(),
          cancellation: token,
        );
        if (_current(seq)) {
          emit(
            state.copy(
              resources: page.data,
              nextResourceCursor: page.nextCursor,
              resourceRevision: page.revision,
              resourcesPage: true,
              offline: _cached,
            ),
          );
        }
      });
    }
    if (!_current(seq)) return;
    await _guard(seq, () async {
      final page = await repository.budgets(cancellation: token);
      if (_current(seq)) emit(state.copy(budgets: page.data, offline: _cached));
    });
    if (_current(seq)) emit(state.copy(loading: false));
  }

  CloudQuery _query({String? cursor}) => CloudQuery(
    start: query.start,
    end: query.end,
    service: query.service,
    region: query.region,
    project: query.project,
    search: query.search,
    basis: query.basis,
    limit: query.limit,
    cursor: cursor,
  );

  Future<void> reload({CloudQuery? newQuery}) async {
    if (!state.isOpen) return;
    final previous = query.toJson();
    final next = newQuery?.toJson();
    final changed =
        next != null &&
        (previous.length != next.length ||
            previous.entries.any((e) => next[e.key] != e.value));
    if (newQuery != null) query = newQuery;
    final seq = ++_sequence;
    final token = _newRequest();
    emit(
      changed
          ? CloudCenterState(
              isOpen: true,
              loading: true,
              provider: state.provider,
              selectedId: state.selectedId,
              connections: state.connections,
              budgets: state.budgets,
            )
          : state.copy(loading: true, offline: false, clearError: true),
    );
    await _load(seq, token);
  }

  Future<void> selectConnection(String id) =>
      open(provider: state.provider, connectionId: id);
  Future<void> loadMoreResources() => _loadMore(false);
  Future<void> loadMoreCosts() => _loadMore(true);
  Future<void> _loadMore(bool costs) async {
    final id = state.selectedId;
    final cursor = costs ? state.nextCostCursor : state.nextResourceCursor;
    if (id == null || cursor == null || state.loading) return;
    final seq = _sequence;
    final token = _cancellation;
    emit(state.copy(loading: true));
    await _guard(seq, () async {
      if (costs) {
        final page = await repository.costs(
          id,
          _query(cursor: cursor),
          cancellation: token,
        );
        if (!_current(seq)) return;
        if (page.revision != state.costRevision) {
          throw const CloudFailure(
            'revisionExpired',
            'Costs changed; reload the list',
          );
        }
        emit(
          state.copy(
            costs: List.unmodifiable([...state.costs, ...page.data]),
            nextCostCursor: page.nextCursor,
            costsPage: true,
            offline: _cached,
          ),
        );
      } else {
        final page = await repository.resources(
          id,
          _query(cursor: cursor),
          cancellation: token,
        );
        if (!_current(seq)) return;
        if (page.revision != state.resourceRevision) {
          throw const CloudFailure(
            'revisionExpired',
            'Resources changed; reload the list',
          );
        }
        emit(
          state.copy(
            resources: List.unmodifiable([...state.resources, ...page.data]),
            nextResourceCursor: page.nextCursor,
            resourcesPage: true,
            offline: _cached,
          ),
        );
      }
    });
    if (_current(seq)) emit(state.copy(loading: false));
  }

  Future<void> loadUsage(String resourceId) async {
    if (!state.isOpen) return;
    final seq = _sequence;
    final selection = ++_usageSequence;
    _usageCancellation?.cancel();
    final token = _usageCancellation = CloudCancellation();
    emit(state.copy(usage: [], clearError: true));
    try {
      final page = await repository.usage(
        resourceId,
        _query(),
        cancellation: token,
      );
      if (_current(seq) && selection == _usageSequence) {
        emit(state.copy(usage: page.data, offline: _cached));
      }
    } on Object catch (error) {
      if (_current(seq) && selection == _usageSequence) {
        emit(state.copy(error: _failure(error)));
      }
    }
  }

  Future<void> saveBudget(BudgetRule rule) async {
    final seq = _sequence;
    await _guard(seq, () async {
      final saved = await repository.saveBudget(
        rule,
        cancellation: _cancellation,
      );
      if (_current(seq)) {
        emit(
          state.copy(
            budgets: List.unmodifiable([
              ...state.budgets.where((r) => r.id != saved.id),
              saved,
            ]),
          ),
        );
      }
    });
  }

  /// Enqueue server work without altering any source timestamps or local totals.
  Future<void> refresh({String dataset = 'costs'}) async {
    final id = state.selectedId;
    if (id == null) {
      await reload();
      return;
    }
    final seq = _sequence;
    await _guard(seq, () async {
      var job = await repository.sync(
        id,
        dataset: dataset,
        cancellation: _cancellation,
      );
      if (!_current(seq)) return;
      emit(state.copy(syncJob: job));
      for (
        var attempt = 0;
        attempt < 20 && ['queued', 'running', 'retrying'].contains(job.state);
        attempt++
      ) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (!_current(seq)) return;
        job = (await repository.syncJob(
          job.id,
          cancellation: _cancellation,
        )).data;
        if (_current(seq)) emit(state.copy(syncJob: job));
      }
      if (_current(seq)) await reload();
    });
  }

  void setForeground(bool foreground) {
    _poller?.cancel();
    _poller = null;
    if (foreground && state.isOpen) {
      _poller = Timer.periodic(const Duration(seconds: 60), (_) {
        if (!state.loading) unawaited(reload());
      });
    }
  }

  void closePanel() {
    ++_sequence;
    _cancellation?.cancel();
    _usageCancellation?.cancel();
    _poller?.cancel();
    _poller = null;
    if (!isClosed) emit(const CloudCenterState());
  }

  @override
  Future<void> close() {
    closePanel();
    return super.close();
  }
}
