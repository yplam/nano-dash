import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/weather.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/weather_cubit.dart';
import '../weather_visuals.dart';

/// How many upcoming hours the hourly strip shows.
const int _kHourCount = 12;

/// How many days the daily list shows.
const int _kDayCount = 7;

/// The full weather page shown by `WeatherModule`: current conditions, an
/// hourly strip, and a multi-day forecast, rendered from [WeatherCubit]. Every
/// spacing/size comes from [PanelTheme] so it scales with the panel and reads as
/// one surface with the other modules.
class WeatherDetailView extends StatefulWidget {
  const WeatherDetailView({super.key});

  @override
  State<WeatherDetailView> createState() => _WeatherDetailViewState();
}

class _WeatherDetailViewState extends State<WeatherDetailView> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    context.read<WeatherCubit>().setLanguage(language);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : constraints.maxHeight,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : constraints.maxWidth,
        );
        return BlocBuilder<WeatherCubit, WeatherState>(
          builder: (context, state) => _body(context, side, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, double side, WeatherState state) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side, shape: PanelShape.square);

    final data = state.data;
    if (data == null) {
      // No city, still loading the first result, or the last fetch failed.
      return Center(
        child: state.loading
            ? const CircularProgressIndicator()
            : Text(
                l10n.weatherError,
                style: panelFont(
                  m.fontMd,
                  m.weightRegular,
                  colors.onSurfaceVariant,
                ),
              ),
      );
    }

    final localeName = Localizations.localeOf(context).toString();

    return SingleChildScrollView(
      padding: m.pageInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CurrentCard(side: side, data: data),
          if (data.hourly.isNotEmpty) ...[
            SizedBox(height: m.gap),
            _HourlyCard(
              side: side,
              hours: data.hourly.take(_kHourCount).toList(),
              localeName: localeName,
              nowLabel: l10n.weatherNow,
            ),
          ],
          if (data.daily.isNotEmpty) ...[
            SizedBox(height: m.gap),
            _DailyCard(
              side: side,
              days: data.daily.take(_kDayCount).toList(),
              localeName: localeName,
              todayLabel: l10n.weatherToday,
              title: l10n.weatherDaily,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared translucent card chrome, matching the other panel modules.
class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.side, required this.child});

  final double side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    return Material(
      color: colors.surface.withValues(alpha: m.cardAlpha),
      borderRadius: BorderRadius.circular(m.cardRadius),
      child: Padding(padding: m.cardPaddingMd, child: child),
    );
  }
}

/// Current conditions: city, hero temperature, condition icon/label, and a row
/// of secondary readings (feels-like, humidity, wind, air quality) as pills.
class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.side, required this.data});

  final double side;
  final WeatherData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final m = PanelTheme.metricsOf(context, side);
    final visual = weatherVisual(
      data.condition,
      isDay: data.isDay,
      brightness: colors.brightness,
    );

    final pills = <Widget>[
      if (data.apparentTemperatureC != null)
        _Pill(
          side: side,
          icon: Icons.thermostat,
          text: l10n.weatherFeelsLike('${data.apparentTemperatureC!.round()}°'),
        ),
      if (data.humidity != null)
        _Pill(
          side: side,
          icon: Icons.water_drop_outlined,
          text: '${data.humidity}%',
        ),
      if (data.windSpeedKmh != null)
        _Pill(
          side: side,
          icon: Icons.air,
          text: '${data.windSpeedKmh!.round()} km/h',
        ),
      if (data.airQuality != null)
        _Pill(
          side: side,
          icon: Icons.blur_on,
          text:
              '${l10n.weatherAirQuality} ${_aqiLabel(l10n, data.airQuality!.level)}',
        ),
    ];

    return _PanelCard(
      side: side,
      child: Column(
        children: [
          Text(
            data.city,
            style: panelFont(m.fontMd, m.weightMedium, colors.onSurfaceVariant),
          ),
          SizedBox(height: side * 0.01),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(visual.icon, color: visual.color, size: side * 0.12),
                SizedBox(width: side * 0.02),
                Text(
                  '${data.temperatureC.round()}°',
                  style: panelFont(side * 0.14, m.weightMedium, colors.primary),
                ),
              ],
            ),
          ),
          Text(
            _conditionLabel(l10n, data.condition, isDay: data.isDay),
            style: panelFont(
              m.fontSm,
              m.weightRegular,
              colors.onSurfaceVariant,
            ),
          ),
          if (pills.isNotEmpty) ...[
            SizedBox(height: m.gap),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: side * 0.02,
              runSpacing: side * 0.02,
              children: pills,
            ),
          ],
        ],
      ),
    );
  }
}

/// A small pill: an icon and a short reading, on the panel's pill surface.
class _Pill extends StatelessWidget {
  const _Pill({required this.side, required this.icon, required this.text});

  final double side;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: side * 0.025,
        vertical: side * 0.012,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: m.pillAlpha),
        borderRadius: BorderRadius.circular(m.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: m.fontSm, color: colors.onSurfaceVariant),
          SizedBox(width: side * 0.008),
          Text(
            text,
            style: panelFont(
              m.fontSm,
              m.weightRegular,
              colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of the next hours.
class _HourlyCard extends StatelessWidget {
  const _HourlyCard({
    required this.side,
    required this.hours,
    required this.localeName,
    required this.nowLabel,
  });

  final double side;
  final List<HourlyForecast> hours;
  final String localeName;
  final String nowLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    final hourFmt = DateFormat.j(localeName);

    return _PanelCard(
      side: side,
      child: SizedBox(
        height: side * 0.26,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: hours.length,
          separatorBuilder: (_, _) => SizedBox(width: side * 0.03),
          itemBuilder: (context, i) {
            final hour = hours[i];
            final visual = weatherVisual(
              hour.condition,
              isDay: hour.isDay,
              brightness: colors.brightness,
            );
            final label = i == 0 ? nowLabel : hourFmt.format(hour.time);
            return SizedBox(
              width: side * 0.15,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: panelFont(
                      m.fontSm,
                      m.weightRegular,
                      colors.onSurfaceVariant,
                    ),
                  ),
                  Icon(visual.icon, color: visual.color, size: side * 0.07),
                  _Precip(
                    side: side,
                    probability: hour.precipitationProbability,
                  ),
                  Text(
                    '${hour.temperatureC.round()}°',
                    style: panelFont(
                      m.fontSm,
                      m.weightMedium,
                      colors.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Multi-day list with a relative high/low range bar.
class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.side,
    required this.days,
    required this.localeName,
    required this.todayLabel,
    required this.title,
  });

  final double side;
  final List<DailyForecast> days;
  final String localeName;
  final String todayLabel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final m = PanelTheme.metricsOf(context, side);
    final dayFmt = DateFormat.E(localeName);

    // Global span across the shown days, so each row's bar reads on one scale.
    var lo = days.first.tempMinC;
    var hi = days.first.tempMaxC;
    for (final d in days) {
      if (d.tempMinC < lo) lo = d.tempMinC;
      if (d.tempMaxC > hi) hi = d.tempMaxC;
    }
    final span = (hi - lo).abs() < 0.5 ? 1.0 : hi - lo;

    return _PanelCard(
      side: side,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: panelFont(m.fontSm, m.weightMedium, colors.onSurfaceVariant),
          ),
          SizedBox(height: side * 0.015),
          for (var i = 0; i < days.length; i++)
            Padding(
              padding: EdgeInsets.symmetric(vertical: side * 0.012),
              child: _dayRow(
                context,
                m,
                days[i],
                label: i == 0 ? todayLabel : dayFmt.format(days[i].date),
                globalLo: lo,
                span: span,
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayRow(
    BuildContext context,
    PanelMetrics m,
    DailyForecast day, {
    required String label,
    required double globalLo,
    required double span,
  }) {
    final colors = Theme.of(context).colorScheme;
    final visual = weatherVisual(day.condition, brightness: colors.brightness);
    final tempStyle = panelFont(m.fontSm, m.weightRegular, colors.onSurface);

    return Row(
      children: [
        SizedBox(
          width: side * 0.13,
          child: Text(label, style: tempStyle),
        ),
        Icon(visual.icon, color: visual.color, size: side * 0.06),
        SizedBox(width: side * 0.02),
        SizedBox(
          width: side * 0.1,
          child: Text(
            '${day.tempMinC.round()}°',
            textAlign: TextAlign.right,
            style: panelFont(
              m.fontSm,
              m.weightRegular,
              colors.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(width: side * 0.025),
        // Fills the slack so the row never overflows the narrow panel.
        Expanded(
          child: _RangeBar(
            lowFrac: (day.tempMinC - globalLo) / span,
            highFrac: (day.tempMaxC - globalLo) / span,
            color: colors.primary,
            track: colors.onSurface.withValues(alpha: 0.12),
            height: side * 0.014,
          ),
        ),
        SizedBox(width: side * 0.025),
        SizedBox(
          width: side * 0.1,
          child: Text('${day.tempMaxC.round()}°', style: tempStyle),
        ),
      ],
    );
  }
}

/// A drop icon + precipitation-probability percentage, or empty space when the
/// chance is unreported or zero (keeps rows aligned).
class _Precip extends StatelessWidget {
  const _Precip({required this.side, required this.probability});

  final double side;
  final int? probability;

  @override
  Widget build(BuildContext context) {
    final m = PanelTheme.metricsOf(context, side);
    final p = probability;
    if (p == null || p <= 0) return SizedBox(height: m.fontSm);
    const color = Colors.lightBlue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.water_drop, size: side * 0.028, color: color),
        SizedBox(width: side * 0.004),
        Text('$p%', style: panelFont(m.fontSm, m.weightRegular, color)),
      ],
    );
  }
}

/// A temperature range bar filling its width: a track with a segment spanning
/// [lowFrac]–[highFrac] (both 0–1 across the shown days' global span).
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.lowFrac,
    required this.highFrac,
    required this.color,
    required this.track,
    required this.height,
  });

  final double lowFrac;
  final double highFrac;
  final Color color;
  final Color track;
  final double height;

  @override
  Widget build(BuildContext context) {
    final lo = lowFrac.clamp(0.0, 1.0);
    final hi = highFrac.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final left = lo * width;
        final segWidth = ((hi - lo) * width).clamp(height, width);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: 0,
                bottom: 0,
                width: segWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The localized short label for [condition] (factoring in [isDay] for clear
/// skies), matching [WeatherData.conditionLabel]'s English wording.
String _conditionLabel(
  AppLocalizations l10n,
  WeatherCondition condition, {
  required bool isDay,
}) {
  switch (condition) {
    case WeatherCondition.clear:
      return isDay
          ? l10n.weatherConditionClearDay
          : l10n.weatherConditionClearNight;
    case WeatherCondition.partlyCloudy:
      return l10n.weatherConditionPartlyCloudy;
    case WeatherCondition.cloudy:
      return l10n.weatherConditionCloudy;
    case WeatherCondition.fog:
      return l10n.weatherConditionFog;
    case WeatherCondition.drizzle:
      return l10n.weatherConditionDrizzle;
    case WeatherCondition.rain:
      return l10n.weatherConditionRain;
    case WeatherCondition.snow:
      return l10n.weatherConditionSnow;
    case WeatherCondition.thunderstorm:
      return l10n.weatherConditionThunderstorm;
  }
}

String _aqiLabel(AppLocalizations l10n, AirQualityLevel level) {
  switch (level) {
    case AirQualityLevel.good:
      return l10n.weatherAqiGood;
    case AirQualityLevel.fair:
      return l10n.weatherAqiFair;
    case AirQualityLevel.moderate:
      return l10n.weatherAqiModerate;
    case AirQualityLevel.poor:
      return l10n.weatherAqiPoor;
    case AirQualityLevel.veryPoor:
      return l10n.weatherAqiVeryPoor;
    case AirQualityLevel.extremelyPoor:
      return l10n.weatherAqiExtremelyPoor;
  }
}
