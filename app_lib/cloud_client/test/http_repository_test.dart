import 'dart:convert';
import 'dart:io';

import 'package:app_cloud/app_cloud.dart';
import 'package:app_cloud_client/app_cloud_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

Map<String, dynamic> envelope(
  dynamic data, {
  String revision = 'one',
  String? cursor,
}) => {
  'schemaVersion': 1,
  'revision': revision,
  'query': <String, dynamic>{},
  'data': data,
  'nextCursor': cursor,
};
void main() {
  test(
    'real backend sends application auth and consumes frozen DTOs',
    () async {
      final fixture = jsonDecode(
        File('../../docs/cloud-center/fixtures/demo-v1.json')
            .readAsStringSync(),
      );
      final client = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer application-token');
        expect(request.url.path, '/v1/connections');
        return http.Response(jsonEncode(envelope(fixture['connections'])), 200);
      });
      final repo = HttpCloudRepository(
        baseUrl: Uri.parse('https://monitor.example'),
        accessToken: 'application-token',
        authContext: 'user-one',
        client: client,
      );
      expect(
        (await repo.connections()).data.first.provider.name,
        fixture['connections'][0]['provider'],
      );
      expect(repo.mode, CloudMode.real);
      expect(repo.cacheNamespace, isNot(contains('application-token')));
    },
  );
  test(
    'real errors never become demo data and cancellation rejects slow results',
    () async {
      final repo = HttpCloudRepository(
        baseUrl: Uri.parse('https://monitor.example'),
        accessToken: 'token',
        authContext: 'a',
        client: MockClient(
          (_) async => http.Response(
            '{"error":{"code":"permissionDenied","message":"secret upstream payload"}}',
            403,
          ),
        ),
      );
      await expectLater(
        repo.connections(),
        throwsA(
          isA<CloudFailure>()
              .having((e) => e.code, 'code', 'permissionDenied')
              .having((e) => e.message, 'message', isNot(contains('secret'))),
        ),
      );
      final cancellation = CloudCancellation();
      final slow = HttpCloudRepository(
        baseUrl: Uri.parse('https://monitor.example'),
        accessToken: 'token',
        authContext: 'a',
        client: MockClient((_) async {
          cancellation.cancel();
          return http.Response(jsonEncode(envelope([])), 200);
        }),
      );
      await expectLater(
        slow.connections(cancellation: cancellation),
        throwsA(isA<CloudFailure>().having((e) => e.code, 'code', 'cancelled')),
      );
    },
  );
  test('real socket offline reads isolated cache and auth failure cannot use cache', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final url = Uri.parse('http://127.0.0.1:${server.port}');
    final requests = server.listen((request) async {
      expect(request.uri.path, '/v1/connections');
      expect(
        request.headers.value('authorization'),
        'Bearer application-token',
      );
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(envelope([])));
      await request.response.close();
    });
    final cache = <String, String>{};
    final repo = HttpCloudRepository(
      baseUrl: url,
      accessToken: 'application-token',
      authContext: 'a',
      allowLoopbackHttp: true,
      readCache: (key) async => cache[key],
      writeCache: (key, payload, revision) async {
        cache[key] = payload;
      },
    );
    expect((await repo.connections()).data, isEmpty);
    expect(repo.lastResponseWasCached, isFalse);
    await server.close(force: true);
    await requests.cancel();
    expect((await repo.connections()).revision, 'one');
    expect(repo.lastResponseWasCached, isTrue);
    final other = HttpCloudRepository(
      baseUrl: url,
      accessToken: 'different',
      authContext: 'b',
      allowLoopbackHttp: true,
    );
    expect(other.cacheNamespace, isNot(repo.cacheNamespace));
    final rotated = HttpCloudRepository(
      baseUrl: url,
      accessToken: 'rotated',
      authContext: 'a',
      allowLoopbackHttp: true,
    );
    expect(rotated.cacheNamespace, isNot(repo.cacheNamespace));
    rotated.close();
    await expectLater(
      other.connections(),
      throwsA(isA<CloudFailure>().having((e) => e.code, 'code', 'offline')),
    );
    final denied = HttpCloudRepository(
      baseUrl: url,
      accessToken: 'revoked',
      authContext: 'a',
      allowLoopbackHttp: true,
      readCache: (key) async => cache[key],
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    await expectLater(
      denied.connections(),
      throwsA(
        isA<CloudFailure>().having(
          (e) => e.code,
          'code',
          'authenticationFailed',
        ),
      ),
    );
    repo.close();
    other.close();
    denied.close();
  });

  test('cleartext only allowed for explicit loopback development', () {
    expect(
      () => HttpCloudRepository(
        baseUrl: Uri.parse('http://monitor.example'),
        accessToken: 'x',
        authContext: 'a',
      ),
      throwsArgumentError,
    );
    expect(
      () => HttpCloudRepository(
        baseUrl: Uri.parse('http://localhost:4000'),
        accessToken: 'x',
        authContext: 'a',
      ),
      throwsArgumentError,
    );
    final repo = HttpCloudRepository(
      baseUrl: Uri.parse('http://127.0.0.1:4000'),
      accessToken: 'x',
      authContext: 'a',
      allowLoopbackHttp: true,
    );
    repo.close();
  });
  test(
    'demo fixture pages 1000 resources and binds cursor to query revision',
    () async {
      final fixture = jsonDecode(
        File('../../docs/cloud-center/fixtures/demo-v1.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final resourceConnection =
          (fixture['resources'] as List).first['connectionId'];
      for (final row in fixture['resources'] as List) {
        row['connectionId'] = resourceConnection;
      }
      final repo = DemoCloudRepository(fixture);
      final connection =
          (fixture['resources'] as List).first['connectionId'] as String;
      final ids = <String>{};
      String? cursor;
      var calls = 0;
      do {
        final page = await repo.resources(
          connection,
          CloudQuery(cursor: cursor, limit: 50),
        );
        expect(page.data.length, lessThanOrEqualTo(50));
        ids.addAll(page.data.map((r) => r.id));
        cursor = page.nextCursor;
        calls++;
      } while (cursor != null);
      expect(ids.length, 1000);
      expect(calls, 20);
      final first = await repo.resources(connection, CloudQuery());
      await expectLater(
        repo.resources(
          connection,
          CloudQuery(cursor: first.nextCursor, search: 'changed'),
        ),
        throwsA(
          isA<CloudFailure>().having((e) => e.code, 'code', 'revisionExpired'),
        ),
      );
      expect(repo.mode, CloudMode.demo);
    },
  );
}
