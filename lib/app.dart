import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/module_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'data/services/http_client.dart';
import 'data/services/locator.dart';
import 'data/services/weather_service.dart';
import 'l10n/app_localizations.dart';
import 'ui/dashboard/dashboard.dart';
import 'ui/modules/clock_module.dart';
import 'ui/weather/weather.dart';

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;
  // Load locale date symbols so the weather forecast can render localized
  // weekday names (e.g. zh) rather than falling back to English.
  await initializeDateFormatting();
  await setUpLocator();
  final prefs = await SharedPreferences.getInstance();
  // The shared network entry point. Created here (like the SharedPreferences
  // instance) and handed to the widget tree rather than living in the locator.
  final httpClient = AppHttpClient();
  runApp(NanoDashApp(prefs: prefs, httpClient: httpClient));
}

class NanoDashApp extends StatelessWidget {
  const NanoDashApp({super.key, required this.prefs, required this.httpClient});

  final SharedPreferences prefs;
  final AppHttpClient httpClient;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // The catalogue of dashboard modules, declared here so the repository
        // layer stays free of UI dependencies.
        RepositoryProvider<ModuleRepository>(
          create: (_) => const ModuleRepository([ClockModule()]),
        ),
        // One persistence backend for every module's settings (dashboard, voice,
        // agent), keyed per module. See SettingsRepository.
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepository(prefs),
        ),
        RepositoryProvider<AppHttpClient>(create: (_) => httpClient),
        RepositoryProvider<WeatherService>(
          create: (context) => WeatherService(context.read<AppHttpClient>()),
        ),
        // Owns the persisted weather config and the cached conditions; depends
        // on WeatherService, so it's registered after it. WeatherCubit polls it,
        // and AgentCubit reads live conditions from it for the weather tool.
        RepositoryProvider<WeatherRepository>(
          create: (context) => WeatherRepository(
            context.read<SettingsRepository>(),
            context.read<WeatherService>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<DashboardCubit>(
            create: (context) => DashboardCubit(
              context.read<SettingsRepository>(),
              context.read<ModuleRepository>(),
            )..load(),
          ),
          BlocProvider<WeatherCubit>(
            create: (context) =>
                WeatherCubit(context.read<WeatherRepository>()),
            lazy: false,
          ),
        ],
        child: MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: const Dashboard(),
        ),
      ),
    );
  }
}
