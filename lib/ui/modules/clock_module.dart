import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/dash_module.dart';
import '../../../../domain/models/weather.dart';
import '../../../../l10n/app_localizations.dart';
import '../weather/weather.dart';

/// A real-time clock. Shows the current time (and optionally date) and ticks
/// every second.
class ClockModule extends DashModule {
  const ClockModule();

  static const String kId = 'clock';

  static const String _kShowSeconds = 'showSeconds';
  static const String _kShowDate = 'showDate';
  static const String _kShowWeather = 'showWeather';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.access_time;

  @override
  String title(AppLocalizations l10n) => l10n.moduleClockTitle;

  @override
  bool get hasSettings => true;

  @override
  DashSettings get defaultSettings => const {
    _kShowSeconds: true,
    _kShowDate: true,
    _kShowWeather: false,
  };

  @override
  Widget buildLcd(BuildContext context, DashSettings settings) {
    return _ClockView(
      showSeconds: settings[_kShowSeconds] as bool? ?? true,
      showDate: settings[_kShowDate] as bool? ?? true,
      showWeather: settings[_kShowWeather] as bool? ?? false,
    );
  }

  @override
  Widget buildSettings(
    BuildContext context,
    DashSettings settings,
    ValueChanged<DashSettings> onChanged,
  ) {
    final l10n = AppLocalizations.of(context);
    bool flag(String key, bool fallback) => settings[key] as bool? ?? fallback;
    void set(String key, bool value) => onChanged({...settings, key: value});

    final showWeather = flag(_kShowWeather, false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(l10n.clockShowSeconds),
          value: flag(_kShowSeconds, true),
          onChanged: (v) => set(_kShowSeconds, v),
        ),
        SwitchListTile(
          title: Text(l10n.clockShowDate),
          value: flag(_kShowDate, true),
          onChanged: (v) => set(_kShowDate, v),
        ),
        SwitchListTile(
          title: Text(l10n.clockShowWeather),
          value: showWeather,
          onChanged: (v) => set(_kShowWeather, v),
        ),
        // The weather readout shown beneath the time owns its own settings
        // (city + unit) via WeatherCubit, so they live alongside the clock's.
        // They only matter when the weather readout is enabled. WeatherSettings
        // is a pure widget; the cubit seeds it and applies its changes.
        if (showWeather) ...[
          const Divider(),
          BlocBuilder<WeatherCubit, WeatherState>(
            builder: (context, state) => WeatherSettings(
              initialConfig: WeatherConfig(
                city: state.city,
                fahrenheit: state.fahrenheit,
              ),
              onConfigChanged: (config) {
                final cubit = context.read<WeatherCubit>();
                cubit.setCity(config.city);
                cubit.setFahrenheit(config.fahrenheit);
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// A round analog clock sized for the 360×360 panel. When [showWeather] is on,
/// it shows the current conditions as a small complication in the dial's lower
/// half, with the hands sweeping above it.
class _ClockView extends StatefulWidget {
  const _ClockView({
    required this.showSeconds,
    required this.showDate,
    required this.showWeather,
  });

  final bool showSeconds;
  final bool showDate;
  final bool showWeather;

  @override
  State<_ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<_ClockView> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.showWeather) return;
    // Feed the current locale to the cubit; this also kicks off the first fetch
    // and refetches when the locale changes (mirrors WeatherDisplay).
    final language = Localizations.localeOf(context).languageCode;
    context.read<WeatherCubit>().setLanguage(language);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showWeather) {
      return _AnalogClock(
        now: _now,
        showSeconds: widget.showSeconds,
        showDate: widget.showDate,
      );
    }
    return BlocBuilder<WeatherCubit, WeatherState>(
      builder: (context, state) => _AnalogClock(
        now: _now,
        showSeconds: widget.showSeconds,
        showDate: widget.showDate,
        weather: state,
      ),
    );
  }
}

class _AnalogClock extends StatelessWidget {
  const _AnalogClock({
    required this.now,
    required this.showSeconds,
    required this.showDate,
    this.weather,
  });

  final DateTime now;
  final bool showSeconds;
  final bool showDate;

  /// Present only when the weather readout is enabled; `null` keeps the centre
  /// to the date alone (or empty).
  final WeatherState? weather;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : constraints.maxHeight;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : constraints.maxWidth;
        final side = math.min(maxW, maxH);

        // Three layers: the static face, the weather/date readout, then the
        // hands on top so they sweep over the readout.
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _FacePainter(colors: colors)),
                ),
                Align(
                  alignment: const Alignment(0, 0.5),
                  child: _CenterReadout(
                    now: now,
                    showDate: showDate,
                    weather: weather,
                    colors: colors,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HandsPainter(
                      now: now,
                      showSeconds: showSeconds,
                      colors: colors,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The current-weather / date complication shown in the dial's lower half, on a
/// translucent chip so it reads over the room background (the hands sweep above
/// it). The time itself is told by the hands, so it carries no digital clock.
class _CenterReadout extends StatelessWidget {
  const _CenterReadout({
    required this.now,
    required this.showDate,
    required this.weather,
    required this.colors,
  });

  final DateTime now;
  final bool showDate;
  final WeatherState? weather;
  final ColorScheme colors;

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final data = weather?.data;

    final lines = <Widget>[];

    if (data != null) {
      final fahrenheit = weather?.fahrenheit ?? false;
      final unit = fahrenheit ? '°F' : '°C';
      final c = data.temperatureC;
      final temp = (fahrenheit ? c * 9 / 5 + 32 : c).round();
      final visual = weatherVisual(data.condition, isDay: data.isDay);
      lines.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icon, color: visual.color, size: 22),
            const SizedBox(width: 6),
            Text(
              '$temp$unit',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (showDate) {
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 2));
      lines.add(
        Text(
          '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
      );
    }

    // Nothing to show (weather off + date off): leave the lower half clean.
    if (lines.isEmpty) return const SizedBox.shrink();

    // A translucent chip keeps the readout legible where the hands sweep over it.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: lines),
      ),
    );
  }
}

/// Paints the static dial: face, minute/hour ticks, and numerals. Painted on
/// the bottom layer (below the weather readout), so it doesn't repaint per tick.
class _FacePainter extends CustomPainter {
  _FacePainter({required this.colors});

  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Face + rim.
    canvas.drawCircle(
      center,
      r,
      Paint()..color = colors.surface.withValues(alpha: 0.5),
    );
    canvas.drawCircle(
      center,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colors.onSurface.withValues(alpha: 0.2),
    );

    // Sixty ticks: long/bold on the hours, short/faint on the minutes.
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final a = i * (math.pi / 30);
      final dir = Offset(math.sin(a), -math.cos(a));
      final isHour = i % 5 == 0;
      final outer = center + dir * (r * 0.96);
      final inner = center + dir * (r * (isHour ? 0.88 : 0.93));
      tickPaint
        ..strokeWidth = isHour ? 3 : 1
        ..color = isHour
            ? colors.onSurface.withValues(alpha: 0.75)
            : colors.onSurfaceVariant.withValues(alpha: 0.45);
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Numerals just inside the tick ring.
    final numR = r * 0.78;
    for (var n = 1; n <= 12; n++) {
      final a = (n % 12) * (math.pi / 6);
      final p = Offset(
        center.dx + numR * math.sin(a),
        center.dy - numR * math.cos(a),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: r * 0.13,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.colors != colors;
}

/// Paints the hour / minute / (optional) second hands and the centre hub on the
/// top layer, so the hands sweep over the weather readout below them.
class _HandsPainter extends CustomPainter {
  _HandsPainter({
    required this.now,
    required this.showSeconds,
    required this.colors,
  });

  final DateTime now;
  final bool showSeconds;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Hands (each carries a short tail past the pivot for balance).
    final hourAngle = (now.hour % 12 + now.minute / 60) * (math.pi / 6);
    final minuteAngle = (now.minute + now.second / 60) * (math.pi / 30);
    _drawHand(canvas, center, hourAngle, r * 0.50, r * 0.12, 6, colors.onSurface);
    _drawHand(
      canvas,
      center,
      minuteAngle,
      r * 0.74,
      r * 0.14,
      4,
      colors.onSurface,
    );
    if (showSeconds) {
      final secondAngle = now.second * (math.pi / 30);
      _drawHand(
        canvas,
        center,
        secondAngle,
        r * 0.80,
        r * 0.18,
        1.5,
        colors.primary,
      );
    }

    // Centre hub: a ring with a coloured pin.
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colors.onSurface,
    );
    canvas.drawCircle(center, 3, Paint()..color = colors.primary);
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double tail,
    double width,
    Color color,
  ) {
    final dir = Offset(math.sin(angle), -math.cos(angle));
    canvas.drawLine(
      center - dir * tail,
      center + dir * length,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HandsPainter old) =>
      old.now != now ||
      old.showSeconds != showSeconds ||
      old.colors != colors;
}
