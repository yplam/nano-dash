import 'dart:convert';

import '../repositories/calendar_repository.dart';
import '../repositories/markets_repository.dart';
import '../repositories/weather_repository.dart';
import 'agent_service.dart';

List<AgentTool> buildAgentTools({
  WeatherRepository? weather,
  CalendarRepository? calendar,
  MarketsRepository? markets,
}) {
  return [
    AgentTool(
      name: 'get_current_time',
      description:
          'The current local date and time, with weekday and timezone.',
      parameters: const {'type': 'object', 'properties': {}},
      run: (_) async {
        final now = DateTime.now();
        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        return jsonEncode({
          'local': now.toIso8601String(),
          'weekday': weekdays[now.weekday - 1],
          'timezone': now.timeZoneName,
        });
      },
    ),
    if (weather != null)
      AgentTool(
        name: 'get_weather',
        description:
            'Current conditions, air quality and a daily forecast for a city. '
            'Temperatures are Celsius. Omit city for the user\'s configured '
            'home city.',
        parameters: const {
          'type': 'object',
          'properties': {
            'city': {
              'type': 'string',
              'description': 'City name, e.g. "Tokyo". Omit for the home city.',
            },
          },
        },
        run: (args) async {
          final city = (args['city'] as String?)?.trim();
          final data = await weather.fetch(
            city == null || city.isEmpty ? weather.config.city : city,
          );
          return jsonEncode({
            'city': data.city,
            'temperatureC': data.temperatureC,
            'feelsLikeC': data.apparentTemperatureC,
            'condition': data.condition.name,
            'humidityPercent': data.humidity,
            'windSpeedKmh': data.windSpeedKmh,
            if (data.airQuality != null)
              'airQuality': data.airQuality!.levelLabel,
            'dailyForecast': [
              for (final day in data.daily)
                {
                  'date': day.date.toIso8601String().substring(0, 10),
                  'condition': day.condition.name,
                  'maxC': day.tempMaxC,
                  'minC': day.tempMinC,
                  if (day.precipitationProbability != null)
                    'precipitationPercent': day.precipitationProbability,
                },
            ],
          });
        },
      ),
    if (calendar != null)
      AgentTool(
        name: 'get_calendar_events',
        description:
            'The user\'s upcoming calendar events (title, start/end, '
            'location), soonest first.',
        parameters: const {'type': 'object', 'properties': {}},
        run: (_) async {
          final result = await calendar.fetch();
          final now = DateTime.now();
          final upcoming =
              result.events.where((e) => e.end.isAfter(now)).toList()
                ..sort((a, b) => a.start.compareTo(b.start));
          return jsonEncode({
            'events': [
              for (final event in upcoming.take(20))
                {
                  'title': event.title,
                  'start': event.start.toIso8601String(),
                  'end': event.end.toIso8601String(),
                  if (event.allDay) 'allDay': true,
                  if (event.location != null) 'location': event.location,
                },
            ],
            if (result.hasErrors)
              'note': 'some calendar sources failed to load',
          });
        },
      ),
    if (markets != null)
      AgentTool(
        name: 'get_market_quotes',
        description:
            'Latest prices for the market symbols the user follows (stocks, '
            'indices, crypto), with change from the previous close.',
        parameters: const {'type': 'object', 'properties': {}},
        run: (_) async {
          final quotes = await markets.fetch();
          return jsonEncode([
            for (final quote in quotes)
              {
                'symbol': quote.symbol,
                'name': quote.displayName,
                'price': quote.price,
                'change': quote.change,
                'changePercent': quote.changePercent,
                if (quote.currency != null) 'currency': quote.currency,
              },
          ]);
        },
      ),
  ];
}
