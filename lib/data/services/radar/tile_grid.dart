import 'dart:math' as math;

/// Geometry for compositing Web-Mercator raster tiles into a circular scope
/// image centred on a lat/lon, shared by the rain overlay and the basemap.
class TileGrid {
  const TileGrid({
    required this.zoom,
    required this.n,
    required this.xf,
    required this.yf,
    required this.x0,
    required this.y0,
    required this.tileSpanPx,
    required this.center,
  });

  /// Chosen zoom level.
  final int zoom;

  /// Tiles per axis at [zoom] (`1 << zoom`); `x` wraps around it, `y` is clamped.
  final int n;

  /// Fractional tile coordinate of the centre.
  final double xf;
  final double yf;

  /// Top-left tile of the covering 2×2 block.
  final int x0;
  final int y0;

  /// One tile's size projected onto the scope, in pixels.
  final double tileSpanPx;

  /// Scope centre in pixels (`side / 2`).
  final double center;

  /// Compute the grid for a scope of [side] px whose radius maps to [rangeKm],
  /// centred on ([lat], [lon]); null if [side] is non-positive or no zoom fits.
  ///
  /// [maxZoom] caps the chosen zoom: when a source only serves tiles up to a
  /// given level (e.g. RainViewer's radar tops out at 7), pass it here. If the
  /// scope is small enough that the natural fit is deeper, the capped tile
  /// simply covers more than the scope and the circular clip trims the excess.
  static TileGrid? forScope({
    required double lat,
    required double lon,
    required double rangeKm,
    required int side,
    int maxZoom = 12,
  }) {
    if (side <= 0) return null;

    final latRad = lat * math.pi / 180;
    final wantSpanKm = 2 * rangeKm;

    // Most detailed zoom (up to [maxZoom]) whose single tile still spans the
    // diameter. Starting at [maxZoom] caps the pick: a scope smaller than a
    // [maxZoom] tile just yields a larger-than-needed tileSpanPx, which the
    // circular clip trims.
    int? zoom;
    double tileKm = 0;
    for (var z = maxZoom; z >= 1; z--) {
      final km = 40075.017 * math.cos(latRad) / (1 << z);
      if (km >= wantSpanKm) {
        zoom = z;
        tileKm = km;
        break;
      }
    }
    if (zoom == null) return null;

    final n = 1 << zoom;
    final xf = (lon + 180) / 360 * n;
    final yf = (1 - _asinh(math.tan(latRad)) / math.pi) / 2 * n;

    // km-per-pixel on the scope: the radius (side/2 px) maps to rangeKm.
    final kmpp = rangeKm / (side / 2);

    return TileGrid(
      zoom: zoom,
      n: n,
      xf: xf,
      yf: yf,
      // A 2×2 block centred on the fractional tile coordinate.
      x0: (xf - 0.5).floor(),
      y0: (yf - 0.5).floor(),
      tileSpanPx: tileKm / kmpp,
      center: side / 2,
    );
  }

  /// Inverse hyperbolic sine, absent from `dart:math`.
  static double _asinh(double x) => math.log(x + math.sqrt(x * x + 1));
}
