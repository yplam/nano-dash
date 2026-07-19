import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/radar.dart';
import '../../../extensions/loggable.dart';
import 'tile_grid.dart';

/// Builds the radar scope's basemap: a raster map from the chosen
/// [RadarMapSource] projected into a circular [ui.Image] centred on the scope,
/// so aircraft and rain are plotted over real geography instead of a blank disc.
///
/// The map is static for a given centre/range/source, so the caller fetches it
/// once and caches it.
class BaseMapService with Loggable {
  BaseMapService(this._dio);

  final Dio _dio;

  Future<Directory?>? _cacheRootFuture;

  @override
  String get logIdentifier => '[BaseMap]';

  Future<Directory?> _cacheRoot() {
    return _cacheRootFuture ??= () async {
      try {
        final support = await getApplicationSupportDirectory();
        final dir = Directory(p.join(support.path, 'radar_tiles'));
        await dir.create(recursive: true);
        return dir;
      } catch (e, st) {
        logWarning(
          'tile cache unavailable — running network-only',
          error: e,
          stackTrace: st,
        );
        return null;
      }
    }();
  }

  /// Composite the basemap into a [side]×[side] circular image centred on
  /// ([lat], [lon]) covering [rangeKm], using [source].
  Future<ui.Image?> fetch({
    required double lat,
    required double lon,
    required double rangeKm,
    required int side,
    required RadarMapSource source,
    String? apiKey,
  }) async {
    final tileset = _tilesetFor(source, apiKey);
    if (tileset == null) {
      logWarning(
        'no tileset for ${source.name} '
        '(keyed source without an API key?) — falling back to plain disc',
      );
      return null;
    }

    final grid = TileGrid.forScope(
      lat: lat,
      lon: lon,
      rangeKm: rangeKm,
      side: side,
    );
    if (grid == null) {
      logWarning(
        'no tile grid for lat=$lat lon=$lon rangeKm=$rangeKm side=$side '
        '— falling back to plain disc',
      );
      return null;
    }

    // The 2×2 block spans 2 tiles per axis; it must reach across the full
    // [side]px disc or the rim will show blank wedges.
    final coverPx = 2 * grid.tileSpanPx;
    if (coverPx < side) {
      logWarning(
        '2×2 block covers ${coverPx.toStringAsFixed(1)}px < side ${side}px '
        '— disc edge will be uncovered',
      );
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.clipPath(
      Path()..addOval(
        Rect.fromCircle(
          center: Offset(grid.center, grid.center),
          radius: side / 2,
        ),
      ),
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;

    var drewAny = false;
    var drawn = 0;
    var requested = 0;
    // Stack each layer bottom-to-top (e.g. Tianditu's base then its labels).
    for (var t = 0; t < tileset.templates.length; t++) {
      final template = tileset.templates[t];
      // Cache tiles under the source, splitting multi-layer sources by layer
      // index so a base and its label overlay don't collide.
      final cacheKey = tileset.templates.length == 1
          ? source.name
          : p.join(source.name, '$t');
      final tiles = await Future.wait([
        for (var j = 0; j < 2; j++)
          for (var i = 0; i < 2; i++)
            _tile(
              template,
              tileset.subdomains,
              grid.zoom,
              grid.x0 + i,
              grid.y0 + j,
              grid.n,
              tileset.headers,
              cacheKey,
            ),
      ]);

      var idx = 0;
      for (var j = 0; j < 2; j++) {
        for (var i = 0; i < 2; i++) {
          requested++;
          final img = tiles[idx++];
          if (img == null) continue;
          final tx = grid.x0 + i;
          final ty = grid.y0 + j;
          final dx = grid.center + (tx - grid.xf) * grid.tileSpanPx;
          final dy = grid.center + (ty - grid.yf) * grid.tileSpanPx;
          canvas.drawImageRect(
            img,
            Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            Rect.fromLTWH(dx, dy, grid.tileSpanPx, grid.tileSpanPx),
            paint,
          );
          img.dispose();
          drewAny = true;
          drawn++;
        }
      }
    }

    if (drawn < requested) {
      logWarning(
        'drew $drawn/$requested ${source.name} tiles — '
        '${requested - drawn} missing, disc will have blank wedges',
      );
    }

    if (!drewAny) {
      logWarning('no ${source.name} tiles drawn — falling back to plain disc');
      return null;
    }
    return recorder.endRecording().toImage(side, side);
  }

  /// The tile URL template(s) and subdomains for [source], or null if the source
  /// can't be served (Tianditu without a key). Templates use `{s}` (subdomain),
  /// `{z}`, `{x}` and `{y}` placeholders and are composited in order.
  _Tileset? _tilesetFor(RadarMapSource source, String? apiKey) {
    switch (source) {
      case RadarMapSource.cartoDark:
        return const _Tileset(
          subdomains: ['a', 'b', 'c'],
          templates: [
            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
          ],
        );
      case RadarMapSource.cartoVoyager:
        return const _Tileset(
          subdomains: ['a', 'b', 'c'],
          templates: [
            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          ],
        );
      case RadarMapSource.openStreetMap:
        return const _Tileset(
          subdomains: [],
          templates: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
        );
      case RadarMapSource.tianditu:
        final key = apiKey?.trim();
        if (key == null || key.isEmpty) return null;
        // Tianditu's Web-Mercator ("w") WMTS: TILEMATRIX = z, TILEROW = y,
        // TILECOL = x, so it drops straight into the shared tile grid. Stack the
        // `vec` base under the `cva` label layer.
        String layer(String name) =>
            'https://t{s}.tianditu.gov.cn/${name}_w/wmts?SERVICE=WMTS'
            '&REQUEST=GetTile&VERSION=1.0.0&LAYER=$name&STYLE=default'
            '&TILEMATRIXSET=w&FORMAT=tiles'
            '&TILEMATRIX={z}&TILEROW={y}&TILECOL={x}&tk=$key';
        // Tianditu rejects non-browser clients: it wants a normal desktop
        // User-Agent and a Referer from an allowed origin (our home page).
        return _Tileset(
          subdomains: const ['0', '1', '2', '3', '4', '5', '6', '7'],
          templates: [layer('vec'), layer('cva')],
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                'AppleWebKit/537.36 (KHTML, like Gecko) '
                'Chrome/125.0.0.0 Safari/537.36',
            'Referer': 'https://nanoda.sh/',
          },
        );
    }
  }

  /// Return one tile from the disk cache (if present) or download and cache it.
  Future<ui.Image?> _tile(
    String template,
    List<String> subdomains,
    int zoom,
    int x,
    int y,
    int n,
    Map<String, String> headers,
    String cacheKey,
  ) async {
    if (y < 0 || y >= n) {
      return null;
    }
    final wx = x % n;
    final xw = wx < 0 ? wx + n : wx;

    final cacheFile = await _tileFile(cacheKey, zoom, xw, y);
    final cached = await _readCachedTile(cacheFile, zoom, xw, y);
    if (cached != null) return cached;

    final s = subdomains.isEmpty ? '' : subdomains[(x + y) % subdomains.length];
    final url = template
        .replaceAll('{s}', s)
        .replaceAll('{z}', '$zoom')
        .replaceAll('{x}', '$xw')
        .replaceAll('{y}', '$y');
    try {
      final res = await _dio.getUri<List<int>>(
        Uri.parse(url),
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
          receiveTimeout: Duration(minutes: 1),
        ),
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) {
        logWarning(
          'empty tile body z$zoom/$xw/$y (HTTP ${res.statusCode}) $url',
        );
        return null;
      }
      final data = Uint8List.fromList(bytes);
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      logDebug(
        'tile z$zoom/$xw/$y ok ${bytes.length}B ${img.width}×${img.height} $url',
      );
      // Only persist tiles that decoded cleanly, so a truncated body can't
      // poison the cache. Failure to write is non-fatal.
      if (cacheFile != null) {
        unawaited(_writeCachedTile(cacheFile, data, zoom, xw, y));
      }
      return img;
    } on DioException catch (e) {
      logWarning(
        'tile z$zoom/$xw/$y failed ${e.type.name} '
        '(HTTP ${e.response?.statusCode}) $url',
        error: e,
      );
      return null;
    } catch (e, st) {
      logWarning(
        'tile z$zoom/$xw/$y decode failed $url',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// The on-disk location for a tile (`<root>/<cacheKey>/<z>/<x>/<y>.png`), or
  /// null when the cache root is unavailable.
  Future<File?> _tileFile(String cacheKey, int zoom, int x, int y) async {
    final root = await _cacheRoot();
    if (root == null) return null;
    return File(p.join(root.path, cacheKey, '$zoom', '$x', '$y.png'));
  }

  /// Read and decode a cached tile, or null on a miss/unreadable file. A corrupt
  /// cache entry is deleted so the next fetch can re-populate it.
  Future<ui.Image?> _readCachedTile(File? file, int zoom, int x, int y) async {
    if (file == null || !file.existsSync()) return null;
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      logWarning('discarding corrupt cached tile z$zoom/$x/$y', error: e);
      try {
        await file.delete();
      } catch (_) {}
      return null;
    }
  }

  /// Persist a freshly fetched tile's bytes; failures are logged, never thrown.
  Future<void> _writeCachedTile(
    File file,
    Uint8List bytes,
    int zoom,
    int x,
    int y,
  ) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: false);
    } catch (e) {
      logWarning('failed to cache tile z$zoom/$x/$y', error: e);
    }
  }
}

/// A basemap provider's tile URL template(s) and load-balancing subdomains.
class _Tileset {
  const _Tileset({
    required this.subdomains,
    required this.templates,
    this.headers = const {'User-Agent': 'nano_dash'},
  });

  /// Values rotated into a template's `{s}` slot; empty for single-host sources.
  final List<String> subdomains;

  /// One URL template per layer, composited bottom-to-top.
  final List<String> templates;

  /// Request headers sent with each tile fetch.
  final Map<String, String> headers;
}
