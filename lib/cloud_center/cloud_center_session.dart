import 'dart:async';
import 'dart:convert';

import 'package:app_bloc_cloud_center/app_bloc_cloud_center.dart';
import 'package:app_cloud/app_cloud.dart';
import 'package:app_cloud_client/app_cloud_client.dart';
import 'package:app_database/app_database.dart';
import 'package:app_lib_engine/app_lib_engine.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cloud_center_projection.dart';

/// Application identity and cache lifecycle, separate from the game save.
class CloudCenterSession extends ChangeNotifier {
  AppDatabase? _database;
  AppDatabase get database => _database ??= AppDatabase();
  final VaultRepository vault;
  final Future<Map<String, dynamic>> Function() loadDemo;
  final VoidCallback onClose;
  final void Function(Map<String, ConsoleSummary>) onSummaries;
  CloudRepository? repository;
  CloudCenterCubit? cubit;
  CloudConsoleModel? console;
  String? configurationError;
  String backendUrl = '';
  String authContext = '';
  bool configuring = false;
  bool _restored = false;
  bool _disposed = false;
  int _generation = 0;
  int _configurationGeneration = 0;
  Future<void>? _sessionWrite;
  StreamSubscription<CloudCenterState>? _subscription;
  String? _selectedConnectionId;
  Future<void>? _preferenceWrite;
  final Map<String, ConsoleSummary> _summaries = {};
  CloudCenterSession({
    AppDatabase? database,
    VaultRepository? vault,
    Future<Map<String, dynamic>> Function()? loadDemo,
    required this.onClose,
    required this.onSummaries,
    // Preserve the public injection name for the private lazy database instance.
    // ignore: prefer_initializing_formals
  }) : _database = database,
       vault = vault ?? SecureStorageVaultRepository(namespace: 'cloud_center'),
       loadDemo = loadDemo ?? _loadDemo;
  static Future<Map<String, dynamic>> _loadDemo() async => jsonDecode(
    await rootBundle.loadString('docs/cloud-center/fixtures/demo-v1.json'),
  ) as Map<String, dynamic>;
  CloudMode? get mode => repository?.mode;
  bool get isOpen => console != null;
  String get _tokenKey => _keyFor(backendUrl, authContext);
  String _keyFor(String url, String context) =>
      'application:${Uri.encodeComponent(url)}:${Uri.encodeComponent(context)}';
  bool _currentConfiguration(int generation) =>
      !_disposed && generation == _configurationGeneration;

  // Persist and replace identities in order; preparation may finish out of order.
  Future<void> _serialize(Future<void> Function() operation) {
    final previous = _sessionWrite;
    final result = previous == null
        ? Future<void>.sync(operation)
        : previous.then((_) => operation());
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _sessionWrite = tail;
    unawaited(
      tail.then((_) {
        if (identical(_sessionWrite, tail)) _sessionWrite = null;
      }),
    );
    return result;
  }

  Future<void> _restore() async {
    if (_restored || _disposed) return;
    _restored = true;
    final generation = _configurationGeneration;
    final configurations = await database.loadCloudConfigurations();
    if (!_currentConfiguration(generation) || configurations.isEmpty) return;
    final config = configurations.first;
    final url = config['backendUrl'] as String;
    final context = config['authContext'] as String;
    CloudRepository next;
    if (config['mode'] == 'demo') {
      final fixture = await loadDemo();
      if (!_currentConfiguration(generation)) return;
      next = DemoCloudRepository(fixture);
    } else if (config['mode'] == 'real') {
      final token = await vault.read(key: _keyFor(url, context));
      if (!_currentConfiguration(generation)) return;
      if (token == null || token.isEmpty) {
        configurationError =
            'Application session missing. Configure backend access again.';
        return;
      }
      try {
        next = _real(token, false, url, context);
      } on Object {
        configurationError = 'Remote backend requires HTTPS. Loopback HTTP requires explicit development selection each session.';
        return;
      }
    } else {
      return;
    }
    await _serialize(() async {
      if (await _replace(next, generation)) {
        backendUrl = url;
        authContext = context;
        _selectedConnectionId = config['selectedConnectionId'] as String?;
      }
    });
  }

  HttpCloudRepository _real(
    String token,
    bool allowLoopbackHttp,
    String url,
    String context,
  ) {
    late final HttpCloudRepository real;
    real = HttpCloudRepository(
      baseUrl: Uri.parse(url),
      accessToken: token,
      authContext: context,
      allowLoopbackHttp: allowLoopbackHttp,
      readCache: (key) => database.readCloudCache(
        namespace: real.cacheNamespace,
        queryKey: key,
      ),
      writeCache: (key, payload, revision) => database.writeCloudCache(
        namespace: real.cacheNamespace,
        queryKey: key,
        payload: payload,
        revision: revision,
      ),
    );
    return real;
  }

  Future<bool> _replace(CloudRepository next, int generation) async {
    if (_currentConfiguration(generation)) await _subscription?.cancel();
    if (_currentConfiguration(generation)) await cubit?.close();
    if (!_currentConfiguration(generation)) {
      if (next is HttpCloudRepository) next.close();
      return false;
    }
    final old = repository;
    if (old is HttpCloudRepository) old.close();
    repository = next;
    _summaries.clear();
    onSummaries({});
    cubit = CloudCenterCubit(
      next,
      responseWasCached: next is HttpCloudRepository
          ? () => next.lastResponseWasCached
          : null,
    );
    _subscription = cubit!.stream.listen(_projectSummary);
    return true;
  }

  void _projectSummary(CloudCenterState state) {
    if (_disposed || console == null) return;
    final selected = state.selectedConnection?.id;
    if (selected != null && selected != _selectedConnectionId) {
      _selectedConnectionId = selected;
      final url = backendUrl;
      final context = authContext;
      final savedMode = mode!.name;
      final generation = _configurationGeneration;
      Future<void> savePreference() async {
        if (!_currentConfiguration(generation)) return;
        await database.saveCloudConfiguration(
          id: 'default',
          backendUrl: url,
          authContext: context,
          mode: savedMode,
          selectedConnectionId: selected,
        );
      }

      final previous = _preferenceWrite;
      final write =
          (previous == null
                  ? Future<void>.sync(savePreference)
                  : previous.then((_) => savePreference()))
              .catchError((Object _) {
                if (_currentConfiguration(generation)) {
                  configurationError =
                      'Connection preference could not be saved.';
                }
              });
      _preferenceWrite = write;
      // Retain pending writes for configure/logout, but never an idle zone's Future.
      unawaited(
        write.then((_) {
          if (identical(_preferenceWrite, write)) _preferenceWrite = null;
        }),
      );
    }
    final summary = projectCloudSummary(state, cubit!.query, console!, mode!);
    if (summary == null) return;
    _summaries[console!.id] = summary;
    onSummaries(Map.unmodifiable(_summaries));
  }

  Future<void> open(CloudConsoleModel target) async {
    final generation = ++_generation;
    console = target;
    if (!_disposed) notifyListeners();
    try {
      await _restore();
      if (_disposed || generation != _generation) return;
      if (repository == null) {
        configuring = true;
        notifyListeners();
        return;
      }
      configuring = false;
      notifyListeners();
      await cubit!.open(
        connectionId: target.target is ProviderConsoleTarget
            ? _selectedConnectionId
            : null,
        provider: target.target is ProviderConsoleTarget
            ? (target.target as ProviderConsoleTarget).provider
            : null,
      );
    } on Object {
      if (_disposed || generation != _generation) return;
      configurationError = 'Cloud configuration unavailable. Choose explicit Demo or configure a backend.';
      configuring = true;
      notifyListeners();
    }
  }

  void showConfiguration() {
    configuring = true;
    cubit?.closePanel();
    if (!_disposed) notifyListeners();
  }

  Future<void> configure({
    required CloudMode mode,
    String backendUrl = '',
    String authContext = '',
    String appToken = '',
    bool allowLoopbackHttp = false,
  }) async {
    ++_generation;
    final generation = ++_configurationGeneration;
    cubit?.closePanel();
    final url = backendUrl.trim();
    final context = authContext.trim();
    final fixture = mode == CloudMode.demo ? await loadDemo() : null;
    if (!_currentConfiguration(generation)) return;
    final next = mode == CloudMode.demo
        ? DemoCloudRepository(fixture!)
        : _real(appToken, allowLoopbackHttp, url, context);
    final tokenKey = _keyFor(url, context);
    await _serialize(() async {
      var wroteToken = false;
      var savedConfiguration = false;
      var installed = false;
      try {
        await _preferenceWrite;
        if (!_currentConfiguration(generation)) return;
        if (mode == CloudMode.real) {
          wroteToken = true;
          await vault.write(key: tokenKey, value: appToken);
          if (!_currentConfiguration(generation)) return;
          final saved = await vault.read(key: tokenKey);
          if (!_currentConfiguration(generation)) return;
          // The vault absorbs platform errors, so verify persistence.
          if (saved != appToken) {
            throw const CloudFailure(
              'secureStorageUnavailable',
              'Application token could not be saved securely',
            );
          }
        }
        await database.saveCloudConfiguration(
          id: 'default',
          backendUrl: url,
          authContext: context,
          mode: mode.name,
        );
        savedConfiguration = true;
        if (!_currentConfiguration(generation)) return;
        installed = await _replace(next, generation);
        if (!installed) return;
        this.backendUrl = url;
        this.authContext = context;
        _restored = true;
        _selectedConnectionId = null;
        configurationError = null;
        closePanel();
      } finally {
        if (!installed) {
          if (next is HttpCloudRepository) next.close();
          if (wroteToken) await vault.delete(key: tokenKey);
          if (savedConfiguration) {
            await database.delete(database.cloudConfigurations).go();
          }
        }
      }
    });
  }

  void setForeground(bool value) {
    cubit?.setForeground(value);
    if (value && cubit?.state.isOpen == true) unawaited(cubit!.reload());
  }

  void closePanel() {
    ++_generation;
    console = null;
    configuring = false;
    cubit?.closePanel();
    onClose();
    if (!_disposed) notifyListeners();
  }

  Future<void> signOut() {
    ++_configurationGeneration;
    _restored = true;
    closePanel();
    return _serialize(() async {
      await _preferenceWrite;
      final current = repository;
      // Earlier serialized work may have opened storage. A session that never
      // used Cloud Center must not initialize platform storage just to log out.
      final activeDatabase = _database;
      if (current is HttpCloudRepository) {
        current.close();
        await activeDatabase?.clearCloudSession(current.cacheNamespace);
        await vault.delete(key: _tokenKey);
      }
      if (activeDatabase != null) {
        // Restoration opens storage before its first await, so interrupted
        // restoration still reaches this cleanup even without a repository.
        for (final config in await activeDatabase.loadCloudConfigurations()) {
          if (config['mode'] == 'real') {
            await vault.delete(
              key: _keyFor(
                config['backendUrl'] as String,
                config['authContext'] as String,
              ),
            );
          }
        }
        await activeDatabase.delete(activeDatabase.cloudConfigurations).go();
      }
      await cubit?.close();
      cubit = null;
      repository = null;
      await _subscription?.cancel();
      _subscription = null;
      _summaries.clear();
      onSummaries({});
    });
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    ++_configurationGeneration;
    _subscription?.cancel();
    final current = repository;
    if (current is HttpCloudRepository) current.close();
    unawaited(_shutdown());
    super.dispose();
  }

  Future<void> _shutdown() async {
    await _sessionWrite;
    await cubit?.close();
    await _preferenceWrite;
    await _database?.close();
  }
}
