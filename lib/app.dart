import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'data/repositories/calendar_repository.dart';
import 'data/repositories/module_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'data/services/calendar/calendar_service.dart';
import 'data/services/location_service.dart';
import 'data/services/locator.dart';
import 'data/services/pico_view_service.dart';
import 'data/services/tray_service.dart';
import 'data/services/weather_service.dart';
import 'data/services/window_service.dart';
import 'domain/models/app_config.dart';
import 'l10n/app_localizations.dart';
import 'ui/calendar/calendar.dart';
import 'ui/dashboard/dashboard.dart';
import 'ui/live2d/cubit/live2d_cubit.dart';
import 'ui/modules/calendar_module.dart';
import 'ui/modules/clock_module.dart';
import 'ui/modules/live2d_module.dart';
import 'ui/modules/now_playing_module.dart';
import 'ui/modules/settings_module.dart';
import 'ui/modules/stopwatch_module.dart';
import 'ui/modules/system_monitor_module.dart';
import 'ui/modules/timer_module.dart';
import 'ui/modules/weather_module.dart';
import 'ui/now_playing/cubit/now_playing_cubit.dart';
import 'ui/settings/cubit/app_config_cubit.dart';
import 'ui/stopwatch/cubit/stopwatch_cubit.dart';
import 'ui/system_monitor/cubit/system_monitor_cubit.dart';
import 'ui/timer/cubit/timer_cubit.dart';
import 'ui/weather/weather.dart';
import 'ui/widgets/panel_text.dart';
import 'ui/widgets/panel_theme.dart';

const Locale kAppLocale = Locale('zh');

Future<void> bootstrapApp({AppFlavor flavor = AppFlavor.desktop}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;
  await WindowService.ensureInitialized();
  await WindowService.setupAndShow(
    size: kDashboardCompactSize,
    minimumSize: const Size(360, 380),
    title: 'NanoDash',
  );
  await initializeDateFormatting();
  await setUpLocator();
  // On desktop, run in the background via a tray icon: closing the window hides
  // it instead of quitting (TrayService.init sets preventClose). The flatpak
  // build has no tray, so it's skipped and the close button quits normally —
  // there'd be no way to restore a hidden window. Labels match the UI locale.
  TrayService? tray;
  if (flavor.hasTray) {
    tray = TrayService();
    await tray.init(lookupAppLocalizations(kAppLocale));
  }
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
    this.tray,
  });

  final SharedPreferences prefs;
  final Dio dio;

  /// Null on the flatpak build, which ships without a system tray.
  final TrayService? tray;

  @override
  Widget build(BuildContext context) {
    final tray = this.tray;
    return MultiRepositoryProvider(
      providers: [
        if (tray != null) RepositoryProvider<TrayService>.value(value: tray),
        RepositoryProvider<ModuleRepository>(
          create: (_) => ModuleRepository([
            const SettingsModule(),
            const ClockModule(),
            const WeatherModule(),
            if (!kIsWeb) const CalendarModule(),
            const TimerModule(),
            const StopwatchModule(),
            if (!kIsWeb) const Live2DModule(),
            if (!kIsWeb) const SystemMonitorModule(),
            if (!kIsWeb) const NowPlayingModule(),
          ]),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepository(prefs),
        ),
        // Shared handle to the single pico_view controller. The Dashboard drives
        // its lifecycle; settings and feature cubits use it for haptics etc.
        RepositoryProvider<PicoViewService>(
          create: (_) => PicoViewService(),
          dispose: (service) => service.dispose(),
        ),
        RepositoryProvider<LocationService>(
          create: (_) => LocationService(dio),
        ),
        RepositoryProvider<WeatherRepository>(
          create: (context) => WeatherRepository(
            context.read<SettingsRepository>(),
            WeatherService(dio),
          ),
        ),
        if (!kIsWeb)
          RepositoryProvider<CalendarRepository>(
            create: (context) => CalendarRepository(
              context.read<SettingsRepository>(),
              CalendarService(dio),
            ),
          ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppConfigCubit>(
            create: (context) =>
                AppConfigCubit(context.read<SettingsRepository>()),
          ),
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
          if (!kIsWeb)
            BlocProvider<CalendarCubit>(
              create: (context) =>
                  CalendarCubit(context.read<CalendarRepository>()),
              lazy: false,
            ),
          BlocProvider<TimerCubit>(
            create: (context) => TimerCubit(
              context.read<SettingsRepository>(),
              context.read<PicoViewService>(),
            ),
            lazy: false,
          ),
          BlocProvider<StopwatchCubit>(
            create: (_) => StopwatchCubit(),
            lazy: false,
          ),
          if (!kIsWeb)
            BlocProvider<SystemMonitorCubit>(
              create: (_) => SystemMonitorCubit(),
              lazy: false,
            ),
          if (!kIsWeb) BlocProvider<Live2dCubit>(create: (_) => Live2dCubit()),
          if (!kIsWeb)
            BlocProvider<NowPlayingCubit>(
              create: (context) =>
                  NowPlayingCubit(context.read<PicoViewService>()),
              lazy: false,
            ),
        ],
        child: BlocBuilder<AppConfigCubit, AppConfig>(
          builder: (context, config) {
            final seed = config.themeColor;
            return MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // Null follows the OS language (resolved against supportedLocales).
              locale: config.followsSystemLocale
                  ? null
                  : Locale(config.localeTag),
              supportedLocales: AppLocalizations.supportedLocales,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: seed),
                fontFamilyFallback: kCjkFontFallback,
                extensions: const [PanelTheme()],
              ),
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: seed,
                  brightness: Brightness.dark,
                ),
                fontFamilyFallback: kCjkFontFallback,
                extensions: const [PanelTheme()],
              ),
              themeMode: config.themeMode,
              home: const Dashboard(),
            );
          },
        ),
      ),
    );
  }
}
