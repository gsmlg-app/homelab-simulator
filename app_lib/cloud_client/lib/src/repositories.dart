import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_cloud/app_cloud.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

typedef CacheReader = Future<String?> Function(String key);
typedef CacheWriter = Future<void> Function(
  String key,
  String payload,
  String revision,
);

abstract class _WireRepository implements CloudRepository {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    CloudQuery? query,
    Map<String, dynamic>? body,
    CloudCancellation? cancellation,
  });
  Future<CloudPage<T>> page<T>(
    String path,
    T Function(dynamic) decode, {
    CloudQuery? query,
    CloudCancellation? cancellation,
  }) async => CloudPage.fromJson(
    await request('GET', path, query: query, cancellation: cancellation),
    decode,
  );
  String segment(String id) => Uri.encodeComponent(id);
  @override
  Future<CloudPage<List<CloudConnection>>> connections({
    CloudCancellation? cancellation,
  }) => page(
    '/connections',
    (data) => List.unmodifiable(
      (data as List).map((e) => CloudConnection.fromJson(e)),
    ),
    cancellation: cancellation,
  );
  @override
  Future<CloudPage<CloudOverview>> overview(
    CloudQuery query, {
    CloudCancellation? cancellation,
  }) => page(
    '/cloud-center/overview',
    (data) => CloudOverview.fromJson(data),
    query: query,
    cancellation: cancellation,
  );
  @override
  Future<CloudPage<ConnectionOverview>> connectionOverview(
    String id,
    CloudQuery query, {
    CloudCancellation? cancellation,
  }) => page(
    '/connections/${segment(id)}/overview',
    (data) => ConnectionOverview.fromJson(data),
    query: query,
    cancellation: cancellation,
  );
  @override
  Future<CloudPage<List<CostRecord>>> costs(
    String id,
    CloudQuery query, {
    CloudCancellation? cancellation,
  }) => page(
    '/connections/${segment(id)}/costs',
    (data) =>
        List.unmodifiable((data as List).map((e) => CostRecord.fromJson(e))),
    query: query,
    cancellation: cancellation,
  );
  @override
  Future<CloudPage<List<CloudResource>>> resources(
    String id,
    CloudQuery query, {
    CloudCancellation? cancellation,
  }) => page(
    '/connections/${segment(id)}/resources',
    (data) =>
        List.unmodifiable((data as List).map((e) => CloudResource.fromJson(e))),
    query: query,
    cancellation: cancellation,
  );
  @override
  Future<CloudPage<List<UsageSample>>> usage(
    String id,
    CloudQuery query, {
    CloudCancellation? cancellation,
  }) => page(
    '/resources/${segment(id)}/usage',
    (data) =>
        List.unmodifiable((data as List).map((e) => UsageSample.fromJson(e))),
    query: query,
    cancellation: cancellation,
  );
  @override
  Future<SyncJob> sync(
    String id, {
    String? dataset,
    CloudCancellation? cancellation,
  }) async => SyncJob.fromJson(
    await request(
      'POST',
      '/connections/${segment(id)}/sync',
      body: {'dataset': ?dataset},
      cancellation: cancellation,
    ),
  );
  @override
  Future<CloudPage<SyncJob>> syncJob(
    String id, {
    CloudCancellation? cancellation,
  }) => page(
    '/sync-jobs/${segment(id)}',
    (data) => SyncJob.fromJson(data),
    cancellation: cancellation,
  );
  @override
  Future<CloudPage<List<BudgetRule>>> budgets({
    CloudCancellation? cancellation,
  }) => page(
    '/budgets',
    (data) =>
        List.unmodifiable((data as List).map((e) => BudgetRule.fromJson(e))),
    cancellation: cancellation,
  );
  @override
  Future<BudgetRule> saveBudget(
    BudgetRule rule, {
    CloudCancellation? cancellation,
  }) async => BudgetRule.fromJson(
    await request(
      'PUT',
      '/budgets/${segment(rule.id)}',
      body: rule.toJson(),
      cancellation: cancellation,
    ),
  );
}

/// Queries only the self-hosted cache API. Contains no cloud-provider API logic.
final class HttpCloudRepository extends _WireRepository {
  final Uri baseUrl;
  final String _accessToken;
  final http.Client _client;
  final CacheReader? readCache;
  final CacheWriter? writeCache;
  final Duration timeout;
  @override
  final String cacheNamespace;
  final Set<String> cachedQueries = {};
  bool get lastResponseWasCached => _lastCached;
  bool _lastCached = false;
  @override
  CloudMode get mode => CloudMode.real;

  HttpCloudRepository({
    required this.baseUrl,
    required String accessToken,
    required String authContext,
    http.Client? client,
    bool allowLoopbackHttp = false,
    this.readCache,
    this.writeCache,
    this.timeout = const Duration(seconds: 15),
  }) : _accessToken = accessToken,
       _client = client ?? http.Client(),
       cacheNamespace = jsonEncode([
         baseUrl.toString(),
         authContext,
         sha256.convert(utf8.encode(accessToken)).toString(),
         'real',
       ]) {
    final loopback = ['localhost', '127.0.0.1', '::1'].contains(baseUrl.host);
    if ((baseUrl.scheme != 'https' &&
            !(baseUrl.scheme == 'http' && allowLoopbackHttp && loopback)) ||
        baseUrl.host.isEmpty ||
        baseUrl.userInfo.isNotEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment ||
        authContext.isEmpty ||
        accessToken.isEmpty) {
      throw ArgumentError(
        'Use HTTPS, or explicitly enable loopback HTTP, with application authorization',
      );
    }
  }
  void close() => _client.close();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    CloudQuery? query,
    Map<String, dynamic>? body,
    CloudCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    final params = query?.toJson().map((key, value) => MapEntry(key, '$value'));
    final uri = Uri.parse(
      '${baseUrl.toString().replaceFirst(RegExp(r'/+$'), '')}/v1$path',
    ).replace(queryParameters: params);
    final key = '$method $uri';
    final headers = {
      'authorization': 'Bearer $_accessToken',
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    http.Response response;
    try {
      response = await (switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: jsonEncode(body)),
        'PUT' => _client.put(uri, headers: headers, body: jsonEncode(body)),
        _ => throw ArgumentError('Unsupported method'),
      }).timeout(timeout);
    } on Object catch (error) {
      cancellation?.throwIfCancelled();
      if (error is! SocketException &&
          error is! http.ClientException &&
          error is! TimeoutException) {
        rethrow;
      }
      final cached = method == 'GET' ? await readCache?.call(key) : null;
      cancellation?.throwIfCancelled();
      if (cached != null) {
        cachedQueries.add(key);
        _lastCached = true;
        return _decode(cached);
      }
      throw const CloudFailure(
        'offline',
        'Backend is unreachable; no cached response is available',
      );
    }
    cancellation?.throwIfCancelled();
    _lastCached = false;
    cachedQueries.remove(key);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var code = switch (response.statusCode) {
        401 => 'authenticationFailed',
        403 => 'permissionDenied',
        409 => 'revisionExpired',
        429 => 'rateLimited',
        _ => 'failed',
      };
      try {
        final upstream = (_decode(response.body)['error'] as Map)['code'];
        if ([
          'unconfigured',
          'waiting',
          'permissionDenied',
          'authenticationFailed',
          'unsupported',
          'rateLimited',
          'failed',
          'revisionExpired',
          'notFound',
          'invalidQuery',
        ].contains(upstream)) {
          code = upstream as String;
        }
      } on Object {
        /* Never expose raw upstream body or diagnostics. */
      }
      throw CloudFailure(code, 'Cloud backend request failed ($code)');
    }
    final decoded = _decode(response.body);
    if (method == 'GET' &&
        decoded['schemaVersion'] == 1 &&
        decoded['revision'] is String) {
      await writeCache?.call(key, response.body, decoded['revision'] as String);
    }
    cancellation?.throwIfCancelled();
    return decoded;
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on Object {
      throw const CloudFailure(
        'invalidResponse',
        'Backend returned an invalid response',
      );
    }
  }
}

/// Receives the frozen fixture explicitly; never selected by the real client.
final class DemoCloudRepository extends _WireRepository {
  final Map<String, dynamic> _fixture;
  final Map<String, Map<String, dynamic>> _jobs = {};
  final Map<String, Map<String, dynamic>> _budgets = {};
  DemoCloudRepository(Map<String, dynamic> fixture)
    : _fixture = jsonDecode(jsonEncode(fixture)) {
    if (_fixture['mode'] != 'demo') {
      throw ArgumentError('Explicit demo fixture required');
    }
    for (final rule in _fixture['budgets'] as List) {
      _budgets[rule['id']] = Map<String, dynamic>.from(rule);
    }
  }
  @override
  CloudMode get mode => CloudMode.demo;
  @override
  String get cacheNamespace => 'demo:fixture-v1';
  static const revision = 'demo-v1';
  List<Map<String, dynamic>> list(String key) =>
      (_fixture[key] as List).map((e) => Map<String, dynamic>.from(e)).toList();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    CloudQuery? query,
    Map<String, dynamic>? body,
    CloudCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    final parts = path
        .split('/')
        .where((p) => p.isNotEmpty)
        .map(Uri.decodeComponent)
        .toList();
    final params = query?.toJson() ?? <String, dynamic>{};
    final connections = list('connections');
    final connectionId = parts.first == 'connections' && parts.length > 1
        ? parts[1]
        : null;
    if (connectionId != null &&
        !connections.any((c) => c['id'] == connectionId)) {
      throw const CloudFailure('notFound', 'Demo connection not found');
    }
    final scopes = list('scopes').map(BillingScope.fromJson);
    List<Map<String, dynamic>> filtered(String key) => list(key).where((r) {
      if (connectionId != null && r['connectionId'] != connectionId) {
        return false;
      }
      if (query?.service != null && r['service'] != query!.service) {
        return false;
      }
      if (query?.region != null && r['region'] != query!.region) return false;
      if (query?.project != null && r['billingScopeId'] != query!.project) {
        return false;
      }
      if (query?.search != null &&
          !'${r['name'] ?? ''} ${r['id']}'.toLowerCase().contains(
            query!.search!.toLowerCase(),
          )) {
        return false;
      }
      if (query?.basis != null && r['basis'] != query!.basis) return false;
      if (query?.start != null &&
          r['start'] != null &&
          DateTime.parse(r['start']).isBefore(query!.start!)) {
        return false;
      }
      if (query?.end != null &&
          r['end'] != null &&
          DateTime.parse(r['end']).isAfter(query!.end!)) {
        return false;
      }
      return true;
    }).toList();
    dynamic data;
    var paged = false;
    if (parts.first == 'budgets') {
      if (method == 'PUT') {
        final rule = BudgetRule.fromJson(body!);
        _budgets[rule.id] = rule.toJson();
        return rule.toJson();
      }
      data = _budgets.values.toList();
    } else if (parts.first == 'sync-jobs') {
      data = _jobs[parts.last];
      if (data == null) {
        throw const CloudFailure('notFound', 'Demo job not found');
      }
    } else if (parts.last == 'sync') {
      final id = 'demo-$connectionId-${body?['dataset'] ?? 'costs'}';
      return _jobs.putIfAbsent(
        id,
        () => {
          'id': id,
          'state': 'succeeded',
          'connectionId': connectionId,
          'dataset': body?['dataset'] ?? 'costs',
          'attempts': 1,
          'errorCode': null,
        },
      );
    } else if (path == '/connections') {
      data = connections;
    } else if (parts.last == 'overview') {
      final totals = aggregateCosts(
        filtered('costs').map(CostRecord.fromJson),
        scopes: scopes,
      ).map((t) => t.toJson()).toList();
      if (connectionId == null) {
        data = {
          'totals': totals,
          'connections': connections,
          'coverage': [
            'Demo only: synthetic billing; fixed Cloudflare subscriptions excluded',
          ],
        };
      } else {
        final connection = connections.singleWhere(
          (c) => c['id'] == connectionId,
        );
        data = {
          'connection': connection,
          'totals': totals,
          'resourceCount': filtered('resources').length,
          'statuses': connection['statuses'],
        };
      }
    } else if (parts.last == 'resources' || parts.last == 'costs') {
      data = filtered(parts.last);
      paged = true;
    } else if (parts.first == 'resources' && parts.last == 'usage') {
      data = filtered('usage')
          .where((r) => r['resourceId'] == parts[1])
          .toList();
      paged = true;
    } else {
      throw const CloudFailure('notFound', 'Unknown Demo route');
    }
    String? next;
    if (paged) {
      final context = jsonEncode([
        path,
        {...params}..remove('cursor'),
        revision,
      ]);
      var offset = 0;
      if (query?.cursor != null) {
        try {
          final cursor = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(query!.cursor!))),
          ) as Map;
          if (cursor['context'] != context ||
              cursor['offset'] is! int ||
              (cursor['offset'] as int) < 0) {
            throw const FormatException();
          }
          offset = cursor['offset'] as int;
        } on Object {
          throw const CloudFailure(
            'revisionExpired',
            'Demo query changed; restart pagination',
          );
        }
      }
      final rows = data as List;
      final end = (offset + (query?.limit ?? 50)).clamp(0, rows.length);
      if (offset > rows.length) {
        throw const CloudFailure('revisionExpired', 'Invalid page offset');
      }
      if (end < rows.length) {
        next = base64Url.encode(
          utf8.encode(jsonEncode({'context': context, 'offset': end})),
        );
      }
      data = rows.sublist(offset, end);
    }
    return {
      'schemaVersion': 1,
      'revision': revision,
      'query': params,
      'data': data,
      'nextCursor': next,
    };
  }
}
