import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';

import '../../../extensions/loggable.dart';
import 'tile_grid.dart';

/// A composited rain frame: the pixels plus the frame's capture time.
class RainResult {
  RainResult(this.image, this.time);

  final ui.Image image;
  final DateTime time;
}

/// Builds a rain-radar overlay from [RainViewer](https://www.rainviewer.com/).
///
/// Reads the public `weather-maps.json` index, projects the covering Web-Mercator
/// tiles of the latest radar frame into a single circular [ui.Image] centred on
/// the scope.
class RainRadarService with Loggable {
  RainRadarService(this._dio);

  final Dio _dio;

  @override
  String get logIdentifier => '[RainRadar]';

  static const String _metaUrl =
      'https://api.rainviewer.com/public/weather-maps.json';

  /// Tile pixel size to request (RainViewer offers 256 or 512).
  static const int _tilePx = 512;

  /// Colour scheme (2 = "Universal Blue") and options (`smooth_snow`).
  static const String _tileStyle = '2/1_1.png';

  /// RainViewer's radar tiles are only served up to this zoom level; requesting
  /// a deeper tile returns "zoom level not supported". We cap [TileGrid] here so
  /// a small scope reuses the zoom-7 tile (which covers more than the scope; the
  /// circular clip trims the excess) instead of dropping the rain layer.
  static const int _maxZoom = 7;

  /// Composite the latest rain frame into a [side]×[side] circular image centred
  /// on ([lat], [lon]) covering [rangeKm]. Returns null on any failure (missing
  /// data, network error) so the caller can simply skip the layer.
  Future<RainResult?> fetch({
    required double lat,
    required double lon,
    required double rangeKm,
    required int side,
  }) async {
    if (side <= 0) {
      logWarning('fetch skipped: non-positive side=$side');
      return null;
    }

    final Response<Object?> meta;
    try {
      meta = await _dio.getUri<Object?>(Uri.parse(_metaUrl));
    } on DioException catch (e) {
      logWarning('meta request failed: $_metaUrl', error: e);
      return null;
    }
    final root = meta.data is Map
        ? Map<String, Object?>.from(meta.data as Map)
        : null;
    if (root == null) {
      logWarning('meta parse failed: data is ${meta.data.runtimeType}');
      return null;
    }

    final host = root['host'] as String?;
    final radar = root['radar'];
    if (host == null || radar is! Map) {
      logWarning(
        'meta missing host/radar: host=$host radar=${radar.runtimeType}',
      );
      return null;
    }
    final past = radar['past'];
    if (past is! List || past.isEmpty) {
      logWarning('meta has no past frames: past=${past.runtimeType}');
      return null;
    }
    final latest = past.last;
    if (latest is! Map) {
      logWarning('latest frame not a map: ${latest.runtimeType}');
      return null;
    }
    final path = latest['path'] as String?;
    final timeSec = (latest['time'] as num?)?.toInt();
    if (path == null || timeSec == null) {
      logWarning('latest frame missing path/time: path=$path time=$timeSec');
      return null;
    }
    // Web-Mercator tile geometry for the scope (shared with the basemap).
    final grid = TileGrid.forScope(
      lat: lat,
      lon: lon,
      rangeKm: rangeKm,
      side: side,
      maxZoom: _maxZoom,
    );
    if (grid == null) {
      logWarning('TileGrid.forScope returned null');
      return null;
    }
    final center = grid.center;
    final tiles = await Future.wait([
      for (var j = 0; j < 2; j++)
        for (var i = 0; i < 2; i++)
          _tile(host, path, grid.zoom, grid.x0 + i, grid.y0 + j, grid.n),
    ]);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.clipPath(
      Path()..addOval(
        Rect.fromCircle(center: Offset(center, center), radius: side / 2),
      ),
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;

    var drewAny = false;
    var idx = 0;
    for (var j = 0; j < 2; j++) {
      for (var i = 0; i < 2; i++) {
        final img = tiles[idx++];
        if (img == null) continue;
        final tx = grid.x0 + i;
        final ty = grid.y0 + j;
        final dx = center + (tx - grid.xf) * grid.tileSpanPx;
        final dy = center + (ty - grid.yf) * grid.tileSpanPx;
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromLTWH(dx, dy, grid.tileSpanPx, grid.tileSpanPx),
          paint,
        );
        img.dispose();
        drewAny = true;
      }
    }

    if (!drewAny) {
      logWarning('no tiles drawn (all null/skipped) — no rain overlay');
      return null;
    }

    final image = await recorder.endRecording().toImage(side, side);
    return RainResult(
      image,
      DateTime.fromMillisecondsSinceEpoch(timeSec * 1000),
    );
  }

  /// Download and decode one tile, or null if the fetch/decode fails. Tiles
  /// outside the valid `y` range are skipped; `x` wraps around the globe.
  Future<ui.Image?> _tile(
    String host,
    String path,
    int zoom,
    int x,
    int y,
    int n,
  ) async {
    if (y < 0 || y >= n) {
      return null;
    }
    final wx = x % n;
    final url =
        '$host$path/$_tilePx/$zoom/${wx < 0 ? wx + n : wx}/$y/$_tileStyle';
    try {
      final res = await _dio.getUri<List<int>>(
        Uri.parse(url),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) {
        logWarning('tile empty response: $url');
        return null;
      }
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      logWarning('tile fetch/decode failed: $url', error: e);
      return null;
    }
  }
}
