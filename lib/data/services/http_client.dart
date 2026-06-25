import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown by [AppHttpClient] when a request completes with a non-2xx status.
class HttpRequestException implements Exception {
  HttpRequestException(this.url, this.statusCode, this.body);

  final Uri url;
  final int statusCode;
  final String body;

  @override
  String toString() => 'HttpRequestException($statusCode for $url)';
}

/// The single network entry point for the whole app.
///
/// Everything that talks to the network goes through one of these so the
/// cross-cutting concerns — timeouts, JSON decoding, and (later) an HTTP/SOCKS
/// proxy — live in one place instead of being scattered across feature code.
///
/// Proxy support hook: the underlying [http.Client] is injected, so wiring a
/// proxy later is just a matter of constructing this with an `IOClient` whose
/// `HttpClient.findProxy` is set, without touching any caller.
class AppHttpClient {
  AppHttpClient({
    http.Client? inner,
    this._timeout = const Duration(seconds: 15),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration _timeout;

  /// GETs [url] and decodes a JSON body. Throws [HttpRequestException] on a
  /// non-2xx response and [TimeoutException]/[http.ClientException] on transport
  /// failures.
  Future<Object?> getJson(Uri url, {Map<String, String>? headers}) async {
    final res = await _inner.get(url, headers: headers).timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpRequestException(url, res.statusCode, res.body);
    }
    // bodyBytes + explicit utf8 so non-ASCII payloads (e.g. localized place
    // names) decode correctly regardless of the response's declared charset.
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  void close() => _inner.close();
}
