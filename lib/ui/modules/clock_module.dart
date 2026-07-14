import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nano_dash/domain/models/dashboard.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/module.dart';
import '../dashboard/cubit/dashboard_cubit.dart';
import '../weather/weather.dart';
import '../widgets/assistant_overlay.dart';
import 'weather_module.dart';

/// A real-time digital clock. Shows the current time and date and ticks every second.
class ClockModule extends Module {
  const ClockModule();

  static const String kId = 'clock';

  static const String _kShowSeconds = 'showSeconds';
  static const String _kUse24Hour = 'use24Hour';
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
  ModuleSettings get defaultSettings => const {
    _kShowSeconds: true,
    _kUse24Hour: true,
    _kShowWeather: false,
  };

  @override
  Widget build(BuildContext context, ModuleSettings settings) {
    return _ClockView(
      showSeconds: settings[_kShowSeconds] as bool? ?? true,
      use24Hour: settings[_kUse24Hour] as bool? ?? true,
      showWeather: settings[_kShowWeather] as bool? ?? false,
    );
  }

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    final l10n = AppLocalizations.of(context);
    bool flag(String key, bool fallback) => settings[key] as bool? ?? fallback;
    void set(String key, bool value) => onChanged({...settings, key: value});

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: Text(l10n.clockUse24Hour),
          value: flag(_kUse24Hour, true),
          onChanged: (v) => set(_kUse24Hour, v),
        ),
        SwitchListTile(
          title: Text(l10n.clockShowSeconds),
          value: flag(_kShowSeconds, true),
          onChanged: (v) => set(_kShowSeconds, v),
        ),
        SwitchListTile(
          title: Text(l10n.clockShowWeather),
          value: flag(_kShowWeather, false),
          onChanged: (v) => set(_kShowWeather, v),
        ),
      ],
    );
  }
}

/// A digital clock sized for the panel.
class _ClockView extends StatefulWidget {
  const _ClockView({
    required this.showSeconds,
    required this.use24Hour,
    required this.showWeather,
  });

  final bool showSeconds;
  final bool use24Hour;
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
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static const String _fontFamily = 'Nunito';

  TextStyle _font(
    double size,
    double weight,
    Color color, {
    double height = 1,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      height: height,
      color: color,
      fontVariations: [FontVariation('wght', weight)],
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = _now;
    final localeName = Localizations.localeOf(context).toString();
    // Locale-aware date, e.g. "Monday, Jan 5" (en) or "1月5日 星期一" (zh).
    final dateText = DateFormat.MMMEd(localeName).format(now);

    final hh = widget.use24Hour
        ? now.hour.toString().padLeft(2, '0')
        : (now.hour % 12 == 0 ? 12 : now.hour % 12).toString();
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final ampm = now.hour < 12 ? 'AM' : 'PM';

    // The time digits carry the theme's primary tint, so changing the app
    // theme (e.g. the seed color) recolors the clock.
    final timeColor = colors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : constraints.maxHeight;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : constraints.maxWidth;
        final side = math.min(maxW, maxH);

        // Count the trailing readouts (the 12-hour AM/PM marker and/or the
        // seconds). Each one widens the time row, so on the round 360px panel
        // we shrink the hero digits as more are shown — that keeps HH:MM:SS
        // clear of the circle's edge rather than letting it run into the bezel.
        final trailingCount =
            (widget.use24Hour ? 0 : 1) + (widget.showSeconds ? 1 : 0);
        final hourSize =
            side *
            switch (trailingCount) {
              0 => 0.30,
              1 => 0.25,
              _ => 0.21,
            };
        // The date keeps a steady size regardless of the time digits so it
        // stays legible even when the hero shrinks.
        final dateSize = side * 0.055;

        // The seconds and the 12-hour AM/PM marker stack in a slim column off
        // the right of the hero HH:MM, sharing one small font to save width.
        // The seconds sit on the *same* baseline as HH:MM (so their digits line
        // up along the bottom rather than dropping below), with AM/PM above.
        final trailingSize = hourSize * 0.4;
        final trailingStyle = _font(trailingSize, 500, timeColor);
        // The AM/PM marker rides a touch smaller than the seconds.
        final ampmStyle = _font(trailingSize * 0.8, 500, timeColor);
        final trailing = <Widget>[];
        // AM/PM stacks above the seconds, but only when both show; kept out of
        // the row's baseline math so the seconds below anchor the column.
        if (!widget.use24Hour && widget.showSeconds) {
          trailing.add(_NoBaseline(child: Text(ampm, style: ampmStyle)));
        }
        // The bottom item owns the HH:MM baseline: the seconds when shown,
        // otherwise the AM/PM marker drops into that same slot.
        if (widget.showSeconds) {
          trailing.add(Text(ss, style: trailingStyle));
        } else if (!widget.use24Hour) {
          trailing.add(Text(ampm, style: ampmStyle));
        }

        final card = <Widget>[];
        card.add(
          Text(
            dateText,
            style: _font(dateSize, 600, colors.onSurfaceVariant, height: 1.1),
          ),
        );
        card.add(SizedBox(height: side * 0.02));
        // Scale the whole time row down if it would ever exceed the card's
        // inner width — a final safety net on top of the per-count sizing so
        // nothing clips on the round panel.
        card.add(
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // Anchor the trailing column to HH:MM by its bottom item's
              // baseline (the seconds, or AM/PM when seconds are hidden).
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$hh:$mm', style: _font(hourSize, 600, timeColor)),
                if (trailing.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: hourSize * 0.06),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: trailing,
                    ),
                  ),
              ],
            ),
          ),
        );

        if (widget.showWeather) {
          card.add(SizedBox(height: side * 0.02));
          card.add(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  context.read<DashboardCubit>().goToModule(WeatherModule.kId),
              child: const WeatherDisplay(),
            ),
          );
        }

        return AssistantOverlay(
          button: AssistantAnchor.bottomCenter,
          dialogue: true,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(side * 0.09),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: side * 0.84),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(side * 0.09),
                    border: Border.all(
                      color: colors.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: side * 0.07,
                      vertical: side * 0.06,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: card,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hides its child's text baseline from a baseline-aligned parent, letting a
/// sibling own the parent's baseline. Used so a stacked AM/PM marker doesn't
/// steal the time row's baseline from the seconds beneath it.
class _NoBaseline extends SingleChildRenderObjectWidget {
  const _NoBaseline({required Widget super.child});

  @override
  _RenderNoBaseline createRenderObject(BuildContext context) =>
      _RenderNoBaseline();
}

class _RenderNoBaseline extends RenderProxyBox {
  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => null;
}
