import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/repositories/module_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'data/services/locator.dart';
import 'data/services/weather_service.dart';
import 'l10n/app_localizations.dart';
import 'ui/dashboard/dashboard.dart';
import 'ui/modules/clock_module.dart';
import 'ui/weather/weather.dart';

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;
  await initializeDateFormatting();
  await setUpLocator();
  final prefs = await SharedPreferences.getInstance();
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  runApp(NanoDashApp(prefs: prefs, dio: dio));
}

class NanoDashApp extends StatelessWidget {
  const NanoDashApp({super.key, required this.prefs, required this.dio});

  final SharedPreferences prefs;
  final Dio dio;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ModuleRepository>(
          create: (_) => const ModuleRepository([ClockModule()]),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepository(prefs),
        ),
        RepositoryProvider<WeatherRepository>(
          create: (context) => WeatherRepository(
            context.read<SettingsRepository>(),
            WeatherService(dio),
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
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: ThemeMode.system,
          home: const Dashboard(),
        ),
      ),
    );
  }
}
