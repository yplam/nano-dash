import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'data/repositories/module_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'data/services/locator.dart';
import 'data/services/tray_service.dart';
import 'data/services/weather_service.dart';
import 'l10n/app_localizations.dart';
import 'ui/dashboard/dashboard.dart';
import 'ui/modules/clock_module.dart';
import 'ui/modules/stopwatch_module.dart';
import 'ui/modules/timer_module.dart';
import 'ui/stopwatch/cubit/stopwatch_cubit.dart';
import 'ui/timer/cubit/timer_cubit.dart';
import 'ui/weather/weather.dart';

const Locale kAppLocale = Locale('zh');

/// CJK font fallbacks so Chinese glyphs render without embedding a font file.
const List<String> kCjkFontFallback = <String>[
  'PingFang SC', // macOS / iOS
  'Microsoft YaHei', // Windows
  'Noto Sans CJK SC', // Linux (Noto package)
  'Noto Sans SC', // Linux alt naming
  'Source Han Sans SC', // Linux alt
  'WenQuanYi Micro Hei', // Linux fallback
];

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: kDashboardCompactSize,
      minimumSize: Size(360, 380),
      center: true,
      title: 'NanoDash',
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
  await initializeDateFormatting();
  await setUpLocator();
  // Run the app in the background via a tray icon; closing the window hides it
  // instead of quitting. Labels use the same locale as the UI.
  final tray = TrayService();
  await tray.init(lookupAppLocalizations(kAppLocale));
  final prefs = await SharedPreferences.getInstance();
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  runApp(NanoDashApp(prefs: prefs, dio: dio, tray: tray));
}

class NanoDashApp extends StatelessWidget {
  const NanoDashApp({
    super.key,
    required this.prefs,
    required this.dio,
    required this.tray,
  });

  final SharedPreferences prefs;
  final Dio dio;
  final TrayService tray;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TrayService>.value(value: tray),
        RepositoryProvider<ModuleRepository>(
          create: (_) => const ModuleRepository([
            ClockModule(),
            TimerModule(),
            StopwatchModule(),
          ]),
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
          BlocProvider<TimerCubit>(
            create: (context) => TimerCubit(context.read<SettingsRepository>()),
            lazy: false,
          ),
          BlocProvider<StopwatchCubit>(
            create: (_) => StopwatchCubit(),
            lazy: false,
          ),
        ],
        child: MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: kAppLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            fontFamilyFallback: kCjkFontFallback,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo,
              brightness: Brightness.dark,
            ),
            fontFamilyFallback: kCjkFontFallback,
          ),
          themeMode: ThemeMode.system,
          home: const Dashboard(),
        ),
      ),
    );
  }
}
