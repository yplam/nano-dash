import 'package:dio/dio.dart';

/// Web (and any non-`dart:io`) fallback: proxies aren't supported, so return
/// null and let the caller fetch directly.
HttpClientAdapter? proxyAdapter(String proxy) => null;
