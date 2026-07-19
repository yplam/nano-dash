import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/radar.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/radar_cubit.dart';

/// Curated, panel-legible flight colours. Each live aircraft is mapped to one
/// by a stable hash of its ICAO hex, so a flight keeps the same colour across
/// polls. Hues are spread and kept bright/saturated enough to read over both
/// the dark and light basemap scrims.
const List<Color> _flightPalette = [
  Color(0xFF4FC3F7), // light blue
  Color(0xFFFFB74D), // orange
  Color(0xFF81C784), // green
  Color(0xFFF06292), // pink
  Color(0xFFBA68C8), // purple
  Color(0xFFFFF176), // yellow
  Color(0xFF4DD0E1), // cyan
  Color(0xFFFF8A65), // deep orange
  Color(0xFF9575CD), // indigo
  Color(0xFFAED581), // lime
  Color(0xFF7986CB), // blue-grey
  Color(0xFFE57373), // red
];

/// A stable palette colour for an aircraft, chosen by hashing its ICAO [hex] so
/// the mapping survives across polls without any per-flight state.
Color flightColor(String hex) {
  var h = 0;
  for (var i = 0; i < hex.length; i++) {
    h = 0x1fffffff & (h * 31 + hex.codeUnitAt(i));
  }
  return _flightPalette[h % _flightPalette.length];
}

/// The radar module's LCD page: a pure ATC-style scope — range rings, compass
/// ticks and a rotating sweep — with live aircraft plotted by bearing/distance
/// and an optional RainViewer rain overlay composited into the circle.
class RadarView extends StatefulWidget {
  const RadarView({super.key});

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<RadarCubit, RadarState>(
      builder: (context, state) {
        final config = state.config;

        return LayoutBuilder(
          builder: (context, constraints) {
            final side = math.min(constraints.maxWidth, constraints.maxHeight);
            final m = PanelTheme.metricsOf(
              context,
              side,
              shape: PanelShape.square,
            );

            if (!config.hasLocation) {
              return _Hint(text: l10n.radarSetLocation, side: side);
            }
            if (!config.flightEnabled && !config.rainEnabled) {
              return _Hint(text: l10n.radarNoLayers, side: side);
            }

            final stale =
                config.flightEnabled &&
                state.updatedAt != null &&
                DateTime.now().difference(state.updatedAt!) >
                    const Duration(seconds: RadarConfig.pollSeconds * 3);

            return Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.deferToChild,
                  onLongPressStart: (d) => _onLongPress(
                    context,
                    d.localPosition,
                    side,
                    config,
                    state.aircraft,
                  ),
                  onTapUp: (_) => context.read<RadarCubit>().selectFlight(null),
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: AnimatedBuilder(
                      animation: _sweep,
                      builder: (context, _) => CustomPaint(
                        painter: _RadarPainter(
                          aircraft: config.flightEnabled
                              ? state.aircraft
                              : const [],
                          baseMap: state.baseMapImage,
                          mapDark: config.mapSource.dark,
                          attribution: config.mapSource.attribution,
                          rain: config.rainEnabled ? state.rainImage : null,
                          centerLat: config.centerLat,
                          centerLon: config.centerLon,
                          rangeKm: config.rangeKm,
                          sweep: _sweep.value,
                          selectedHex: config.flightEnabled
                              ? state.selectedHex
                              : null,
                          trails: config.flightEnabled
                              ? state.trails
                              : const {},
                          colors: colors,
                          fontSm: m.fontSm,
                          fontXs: m.fontXs,
                          weight: m.weightMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Select the aircraft nearest to a long-press [local] position (within a
  /// touch-sized slop), or clear the selection when the press misses everything.
  void _onLongPress(
    BuildContext context,
    Offset local,
    double side,
    RadarConfig config,
    List<Aircraft> aircraft,
  ) {
    if (!config.flightEnabled) return;
    final radius = side / 2;
    final center = Offset(radius, radius);
    final kmpp = config.rangeKm / radius;
    final cosLat = math.cos(config.centerLat * math.pi / 180);

    String? best;
    var bestDist = side * 0.06; // touch slop, ~22px on the round panel
    for (final ac in aircraft) {
      final dxKm = (ac.lon - config.centerLon) * cosLat * 111.32;
      final dyKm = (ac.lat - config.centerLat) * 111.32;
      final pos = Offset(center.dx + dxKm / kmpp, center.dy - dyKm / kmpp);
      final d = (pos - local).distance;
      if (d < bestDist) {
        bestDist = d;
        best = ac.hex;
      }
    }
    context.read<RadarCubit>().selectFlight(best);
  }

  String _statusText(
    AppLocalizations l10n,
    RadarConfig config,
    RadarState state,
  ) {
    final parts = <String>[];
    if (config.flightEnabled) {
      parts.add(config.flightSource.label);
      parts.add(l10n.radarAircraftCount(state.aircraft.length));
    }
    if (config.rainEnabled) parts.add(l10n.radarRainShort);
    return parts.join(' · ');
  }
}

/// Centered guidance shown when the scope can't render yet (no location, or no
/// layer enabled).
class _Hint extends StatelessWidget {
  const _Hint({required this.text, required this.side});

  final String text;
  final double side;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: side * 0.18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar, size: side * 0.14, color: colors.primary),
            SizedBox(height: side * 0.04),
            Text(
              text,
              textAlign: TextAlign.center,
              style: panelFont(16, 500, colors.onSurfaceVariant, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints the scope: rain overlay, rings/ticks, sweep, aircraft and centre mark.
class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.aircraft,
    required this.baseMap,
    required this.mapDark,
    required this.attribution,
    required this.rain,
    required this.centerLat,
    required this.centerLon,
    required this.rangeKm,
    required this.sweep,
    required this.selectedHex,
    required this.trails,
    required this.colors,
    required this.fontSm,
    required this.fontXs,
    required this.weight,
  });

  final List<Aircraft> aircraft;

  /// The basemap composited into the scope circle, drawn under everything.
  final ui.Image? baseMap;

  /// Whether [baseMap] is a dark map; picks the scrim tint that keeps the grid
  /// and aircraft legible (a light scrim over dark maps, a dark one over light).
  final bool mapDark;

  /// Credit line for the active basemap, drawn on the rim.
  final String attribution;

  final ui.Image? rain;
  final double centerLat;
  final double centerLon;
  final double rangeKm;

  /// Sweep phase in [0, 1).
  final double sweep;

  /// ICAO hex of the long-pressed target, or null. When set, the selected
  /// aircraft's glyph and trail are emphasised (the rest dim back) and it shows
  /// its callsign/flight-level label.
  final String? selectedHex;

  /// Every on-scope aircraft's position history, keyed by ICAO hex, oldest fix
  /// first. Each is drawn as a fading route line in the flight's colour.
  final Map<String, List<TrailPoint>> trails;

  final ColorScheme colors;
  final double fontSm;
  final double fontXs;
  final double weight;

  /// Targets older than this (seconds) are drawn dimmed.
  static const int _staleSeconds = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final kmpp = rangeKm / radius;

    // Base disc: the CARTO basemap when loaded, else a plain dark disc. A
    // translucent scrim over the map keeps the grid/aircraft/rain legible.
    final map = baseMap;
    if (map != null) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawImageRect(
        map,
        Rect.fromLTWH(0, 0, map.width.toDouble(), map.height.toDouble()),
        Rect.fromCircle(center: center, radius: radius),
        Paint()..filterQuality = FilterQuality.medium,
      );
      // Scrim: a light veil over a dark map, a heavier dark veil over a light or
      // satellite map, so the grid/aircraft/rain stay legible either way.
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = mapDark
              ? colors.surface.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
      );
      canvas.restore();
    } else {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = colors.surface.withValues(alpha: 0.55),
      );
    }

    // Rain overlay, scaled into the scope and clipped to the circle.
    final rainImage = rain;
    if (rainImage != null) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawImageRect(
        rainImage,
        Rect.fromLTWH(
          0,
          0,
          rainImage.width.toDouble(),
          rainImage.height.toDouble(),
        ),
        Rect.fromCircle(center: center, radius: radius),
        Paint()
          ..filterQuality = FilterQuality.medium
          // Modulate (not plain color) so the image's own alpha is scaled down,
          // dimming the overlay so grid/aircraft stay legible on top.
          ..colorFilter = ColorFilter.mode(
            Colors.white.withValues(alpha: 0.85),
            BlendMode.modulate,
          ),
      );
      canvas.restore();
    }

    _paintGrid(canvas, center, radius);
    _paintSweep(canvas, center, radius);
    _paintTrails(canvas, center, radius, kmpp);
    _paintAircraft(canvas, center, radius, kmpp);
    _paintCenter(canvas, center);
    if (map != null) _paintAttribution(canvas, center, radius);
  }

  /// Required tile attribution for the active basemap, tucked against the rim.
  void _paintAttribution(Canvas canvas, Offset center, double radius) {
    final tp = _text(
      attribution,
      fontXs,
      colors.onSurfaceVariant.withValues(alpha: 0.6),
    );
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy + radius - tp.height - 4),
    );
  }

  void _paintGrid(Canvas canvas, Offset center, double radius) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.primary.withValues(alpha: 0.35);

    // Concentric range rings at 1/3, 2/3 and full range.
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, ring);
    }

    // Cross hairs.
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ring,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ring,
    );

    // Compass ticks every 30°.
    final tick = Paint()
      ..strokeWidth = 1
      ..color = colors.primary.withValues(alpha: 0.4);
    for (var deg = 0; deg < 360; deg += 30) {
      final a = deg * math.pi / 180 - math.pi / 2;
      final outer = Offset(
        center.dx + math.cos(a) * radius,
        center.dy + math.sin(a) * radius,
      );
      final inner = Offset(
        center.dx + math.cos(a) * (radius - (deg % 90 == 0 ? 10 : 6)),
        center.dy + math.sin(a) * (radius - (deg % 90 == 0 ? 10 : 6)),
      );
      canvas.drawLine(inner, outer, tick);
    }

    // North marker, centred on the top of the scope.
    final n = _text('N', fontSm, colors.primary);
    n.paint(canvas, Offset(center.dx - n.width / 2, center.dy - radius + 4));

    // Range label on the outer ring.
    _text(
      '${rangeKm.round()}km',
      fontXs,
      colors.onSurfaceVariant,
    ).paint(canvas, Offset(center.dx + 4, center.dy - radius + 2));
  }

  void _paintSweep(Canvas canvas, Offset center, double radius) {
    final angle = sweep * 2 * math.pi - math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    // Trailing wedge fading out behind the leading edge.
    final shader = SweepGradient(
      colors: [
        colors.primary.withValues(alpha: 0),
        colors.primary.withValues(alpha: 0.28),
      ],
      stops: const [0.78, 1.0],
      transform: GradientRotation(angle - 2 * math.pi),
    ).createShader(rect);
    canvas.drawCircle(center, radius, Paint()..shader = shader);
    canvas.restore();

    // Bright leading line.
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      ),
      Paint()
        ..strokeWidth = 1.5
        ..color = colors.primary.withValues(alpha: 0.8),
    );
  }

  /// Projects a geographic position to a scope offset, matching the hit-test
  /// used by the view's long-press handler.
  Offset _project(double lat, double lon, Offset center, double kmpp) {
    final cosLat = math.cos(centerLat * math.pi / 180);
    final dxKm = (lon - centerLon) * cosLat * 111.32;
    final dyKm = (lat - centerLat) * 111.32;
    return Offset(center.dx + dxKm / kmpp, center.dy - dyKm / kmpp);
  }

  /// Every on-scope aircraft's history as a line in the flight's colour that
  /// fades from faint (oldest fix) to bright (newest), clipped to the scope
  /// circle. When a target is selected, its trail keeps full strength while the
  /// others dim back so the selection stands out.
  void _paintTrails(Canvas canvas, Offset center, double radius, double kmpp) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final ac in aircraft) {
      // Only trace flights currently plotted inside the scope.
      final pos = _project(ac.lat, ac.lon, center, kmpp);
      if ((pos - center).distance > radius - 2) continue;

      final trail = trails[ac.hex];
      if (trail == null || trail.length < 2) continue;

      final selected = ac.hex == selectedHex;
      final emphasis = selectedHex == null || selected ? 1.0 : 0.3;
      final color = flightColor(ac.hex);
      final pts = [
        for (final p in trail) _project(p.lat, p.lon, center, kmpp),
      ];
      for (var i = 0; i < pts.length - 1; i++) {
        // Newer segments toward the aircraft are more opaque.
        final t = (i + 1) / (pts.length - 1);
        paint.color = color.withValues(alpha: (0.1 + 0.7 * t) * emphasis);
        canvas.drawLine(pts[i], pts[i + 1], paint);
      }
    }
    canvas.restore();
  }

  void _paintAircraft(
    Canvas canvas,
    Offset center,
    double radius,
    double kmpp,
  ) {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final planeSize = radius * 0.11;

    for (final ac in aircraft) {
      final pos = _project(ac.lat, ac.lon, center, kmpp);
      if ((pos - center).distance > radius - 2) continue;

      final selected = ac.hex == selectedHex;
      final stale =
          ac.lastContact != null && nowSec - ac.lastContact! > _staleSeconds;
      // Each flight keeps its palette colour; stale contacts and (when a target
      // is selected) the unselected ones dim back so the selection stands out.
      var alpha = 1.0;
      if (stale) alpha *= 0.5;
      if (selectedHex != null && !selected) alpha *= 0.4;
      final color = flightColor(ac.hex).withValues(alpha: alpha);

      _paintPlane(
        canvas,
        pos,
        ac.track,
        color,
        selected ? planeSize * 1.3 : planeSize,
      );

      // Callsign and flight level / speed are shown only for the selected
      // target, so the scope stays uncluttered.
      if (!selected) continue;

      final cs = ac.callsign.isEmpty ? ac.hex.toUpperCase() : ac.callsign;
      final tp = _text(cs, fontXs, color);
      final labelX = pos.dx + planeSize * 0.8;
      tp.paint(canvas, Offset(labelX, pos.dy - tp.height / 2));

      final fl = ac.flightLevel;
      final kt = ac.speedKt;
      if (fl != null || kt != null) {
        final detail = [
          if (fl != null) 'FL$fl',
          if (kt != null) '${kt}kt',
        ].join(' ');
        final dp = _text(detail, fontXs, color.withValues(alpha: 0.75));
        dp.paint(canvas, Offset(labelX, pos.dy + tp.height / 2 - 1));
      }
    }
  }

  /// A heading-oriented Material `flight` glyph of [size] at [pos]. The glyph's
  /// nose points north, so rotating by the track aligns it with the heading;
  /// falls back to an unrotated glyph when [track] is unknown.
  void _paintPlane(
    Canvas canvas,
    Offset pos,
    double? track,
    Color color,
    double size,
  ) {
    const icon = Icons.flight;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (track != null) canvas.rotate(track * math.pi / 180);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  void _paintCenter(Canvas canvas, Offset center) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..color = colors.tertiary;
    canvas.drawLine(center.translate(-4, 0), center.translate(4, 0), paint);
    canvas.drawLine(center.translate(0, -4), center.translate(0, 4), paint);
  }

  TextPainter _text(String s, double size, Color color) => TextPainter(
    text: TextSpan(text: s, style: panelFont(size, weight, color)),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.sweep != sweep ||
      old.aircraft != aircraft ||
      old.baseMap != baseMap ||
      old.mapDark != mapDark ||
      old.attribution != attribution ||
      old.rain != rain ||
      old.rangeKm != rangeKm ||
      old.centerLat != centerLat ||
      old.centerLon != centerLon ||
      old.selectedHex != selectedHex ||
      old.trails != trails;
}
