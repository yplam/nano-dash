import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Build a Dio [HttpClientAdapter] that routes every request through [proxy].
///
/// [proxy] accepts `host:port`, `http(s)://host:port`, or `socks(4|5)://host:port`.
/// Returns null when [proxy] can't be interpreted, so the caller falls back to a
/// direct connection.
HttpClientAdapter? proxyAdapter(String proxy) {
  final directive = _proxyDirective(proxy);
  if (directive == null) return null;
  return IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (_) => '$directive; DIRECT';
      return client;
    },
  );
}

/// Translate a user-entered proxy string into a `findProxy` directive
/// (`PROXY host:port` or `SOCKS host:port`), or null if it's blank/unusable.
String? _proxyDirective(String proxy) {
  var p = proxy.trim();
  if (p.isEmpty) return null;

  final scheme = p.contains('://')
      ? p.substring(0, p.indexOf('://')).toLowerCase()
      : '';
  if (p.contains('://')) p = p.substring(p.indexOf('://') + 3);
  // Drop any trailing path/query — only host:port matters to findProxy.
  final slash = p.indexOf('/');
  if (slash >= 0) p = p.substring(0, slash);
  if (p.isEmpty || !p.contains(':')) return null;

  final isSocks = scheme.startsWith('socks');
  return '${isSocks ? 'SOCKS' : 'PROXY'} $p';
}
