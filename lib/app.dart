import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'data/repositories/agent_repository.dart';
import 'data/repositories/calendar_repository.dart';
import 'data/repositories/markets_repository.dart';
import 'data/repositories/module_repository.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/timer_repository.dart';
import 'data/repositories/usage_monitor_repository.dart';
import 'data/repositories/voice_repository.dart';
import 'data/repositories/weather_repository.dart';
import 'data/services/agent_service.dart';
import 'data/services/agent_tools.dart';
import 'data/services/calendar/calendar_service.dart';
import 'data/services/location_service.dart';
import 'data/services/locator.dart';
import 'data/services/markets/markets_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/panel_display_controller.dart';
import 'data/services/pico_view_service.dart';
import 'data/services/tray_service.dart';
import 'data/services/usage_monitor/usage_monitor_service.dart';
import 'data/services/voice_service.dart';
import 'data/services/weather_service.dart';
import 'data/services/window_service.dart';
import 'domain/models/app_config.dart';
import 'l10n/app_localizations.dart';
import 'ui/agent/agent.dart';
import 'ui/calendar/calendar.dart';
import 'ui/dashboard/dashboard.dart';
import 'ui/live2d/cubit/live2d_cubit.dart';
import 'ui/markets/markets.dart';
import 'ui/modules/agent_module.dart';
import 'ui/modules/calendar_module.dart';
import 'ui/modules/clock_module.dart';
import 'ui/modules/live2d_module.dart';
import 'ui/modules/markets_module.dart';
import 'ui/modules/now_playing_module.dart';
import 'ui/modules/settings_module.dart';
import 'ui/modules/stopwatch_module.dart';
import 'ui/modules/system_monitor_module.dart';
import 'ui/modules/timer_module.dart';
import 'ui/modules/usage_monitor_module.dart';
import 'ui/modules/video_module.dart';
import 'ui/modules/voice_module.dart';
import 'ui/modules/weather_module.dart';
import 'ui/now_playing/cubit/now_playing_cubit.dart';
import 'ui/settings/cubit/app_config_cubit.dart';
import 'ui/stopwatch/cubit/stopwatch_cubit.dart';
import 'ui/system_monitor/cubit/system_monitor_cubit.dart';
import 'ui/timer/cubit/timer_cubit.dart';
import 'ui/timer/models/timer_config.dart';
import 'ui/usage_monitor/usage_monitor.dart';
import 'ui/voice/voice.dart';
import 'ui/weather/weather.dart';
import 'ui/widgets/background_view.dart';
import 'ui/widgets/panel_text.dart';
import 'ui/widgets/panel_theme.dart';

const Locale kAppLocale = Locale('zh');

Future<void> bootstrapApp({AppFlavor flavor = AppFlavor.desktop}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPaintSizeEnabled = true;
  // Register media_kit's native (libmpv) backend before any Player is created.
  if (!kIsWeb) MediaKit.ensureInitialized();
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
  // Host-side notifications.
  final notifications = NotificationService();
  await notifications.init();
  final prefs = await SharedPreferences.getInstance();
  // Warm the background before the first frame, so the dashboard paints whole
  // instead of revealing the backdrop a few frames after the window is up.
  await BackgroundView.precache(
    SettingsRepository(prefs).load(appConfigKey).backgroundPath,
  );
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  runApp(
    NanoDashApp(
      prefs: prefs,
      dio: dio,
      tray: tray,
      notifications: notifications,
    ),
  );
}

class NanoDashApp extends StatelessWidget {
  const NanoDashApp({
    super.key,
    required this.prefs,
    required this.dio,
    required this.notifications,
    this.tray,
  });

  final SharedPreferences prefs;
  final Dio dio;

  /// Host-side system-notification channel.
  final NotificationService notifications;

  /// Null on the flatpak build, which ships without a system tray.
  final TrayService? tray;

  @override
  Widget build(BuildContext context) {
    final tray = this.tray;
    return MultiRepositoryProvider(
      providers: [
        if (tray != null) RepositoryProvider<TrayService>.value(value: tray),
        RepositoryProvider<NotificationService>.value(value: notifications),
        RepositoryProvider<ModuleRepository>(
          create: (_) => ModuleRepository([
            const SettingsModule(),
            const ClockModule(),
            const WeatherModule(),
            const TimerModule(),
            const StopwatchModule(),
            if (!kIsWeb) const CalendarModule(),
            if (!kIsWeb) const MarketsModule(),
            if (!kIsWeb) const Live2DModule(),
            if (!kIsWeb) const SystemMonitorModule(),
            if (!kIsWeb) const UsageMonitorModule(),
            if (!kIsWeb) const NowPlayingModule(),
            if (!kIsWeb) const VoiceModule(),
            if (!kIsWeb) const AgentModule(),
            if (!kIsWeb) const VideoModule(),
          ]),
        ),
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepository(prefs),
        ),
        RepositoryProvider<PanelDisplayController>(
          create: (_) => PanelDisplayController(),
          dispose: (controller) => controller.dispose(),
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
        RepositoryProvider<TimerRepository>(
          create: (context) {
            final l10n = lookupAppLocalizations(kAppLocale);
            return TimerRepository(
              context.read<SettingsRepository>(),
              context.read<PicoViewService>(),
              context.read<NotificationService>(),
              finishedText: l10n.timerNotificationFinished,
              focusDoneText: l10n.timerNotificationFocusDone,
              breakDoneText: l10n.timerNotificationBreakDone,
            );
          },
          dispose: (repository) => repository.dispose(),
        ),
        if (!kIsWeb)
          RepositoryProvider<ReminderRepository>(
            create: (context) => ReminderRepository(
              context.read<SettingsRepository>(),
              context.read<PicoViewService>(),
            ),
            dispose: (repository) => repository.dispose(),
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
        if (!kIsWeb)
          RepositoryProvider<MarketsRepository>(
            create: (context) => MarketsRepository(
              context.read<SettingsRepository>(),
              MarketsService(dio),
            ),
          ),
        if (!kIsWeb)
          RepositoryProvider<UsageMonitorRepository>(
            create: (context) => UsageMonitorRepository(
              context.read<SettingsRepository>(),
              UsageMonitorService(dio),
            ),
          ),
        if (!kIsWeb)
          RepositoryProvider<VoiceRepository>(
            create: (context) => VoiceRepository(
              context.read<SettingsRepository>(),
              VoiceService(),
            ),
            dispose: (repository) => repository.dispose(),
          ),
        if (!kIsWeb)
          RepositoryProvider<AgentRepository>(
            create: (context) {
              final l10n = lookupAppLocalizations(kAppLocale);
              String timerName(TimerConfig config) {
                final name = config.displayName(l10n);
                return name.isEmpty ? config.id : name;
              }

              final display = context.read<PanelDisplayController>();
              final modules = context.read<ModuleRepository>();
              final displayTool = buildDisplayTool(
                display,
                modules: {
                  for (final m in modules.modules)
                    if (m.hasDisplay) m.id: m.title(l10n),
                },
              );
              return AgentRepository(
                context.read<SettingsRepository>(),
                context.read<VoiceRepository>(),
                AgentService(),
                tools: [
                  ...buildAgentTools(
                    weather: context.read<WeatherRepository>(),
                    calendar: context.read<CalendarRepository>(),
                    markets: context.read<MarketsRepository>(),
                    timers: context.read<TimerRepository>(),
                    reminders: context.read<ReminderRepository>(),
                    display: display,
                    timerName: timerName,
                  ),
                  displayTool,
                ],
                displayTool: displayTool,
                contextBuilder: () => buildAgentContext(
                  weather: context.read<WeatherRepository>(),
                  calendar: context.read<CalendarRepository>(),
                  timers: context.read<TimerRepository>(),
                  reminders: context.read<ReminderRepository>(),
                  timerName: timerName,
                ),
                errorLine: l10n.agentErrorLine,
                reminders: context.read<ReminderRepository>(),
                notifications: context.read<NotificationService>(),
                reminderLine: l10n.agentReminderLine,
                missedReminderLine: l10n.agentReminderMissedLine,
                reminderTitle: l10n.reminderNotificationTitle,
                missedReminderTitle: l10n.reminderNotificationMissedTitle,
              );
            },
            dispose: (repository) => repository.dispose(),
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
              context.read<PanelDisplayController>(),
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
          if (!kIsWeb)
            BlocProvider<MarketsCubit>(
              create: (context) =>
                  MarketsCubit(context.read<MarketsRepository>()),
              lazy: false,
            ),
          BlocProvider<TimerCubit>(
            create: (context) => TimerCubit(context.read<TimerRepository>()),
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
          if (!kIsWeb)
            BlocProvider<UsageMonitorCubit>(
              create: (context) =>
                  UsageMonitorCubit(context.read<UsageMonitorRepository>()),
              lazy: false,
            ),
          if (!kIsWeb)
            BlocProvider<VoiceCubit>(
              create: (context) => VoiceCubit(context.read<VoiceRepository>()),
              lazy: false,
            ),
          if (!kIsWeb)
            BlocProvider<AgentCubit>(
              create: (context) => AgentCubit(context.read<AgentRepository>()),
              lazy: false,
            ),
          if (!kIsWeb)
            BlocProvider<Live2dCubit>(
              create: (context) => Live2dCubit(
                context.read<SettingsRepository>(),
                voice: context.read<VoiceRepository>(),
                agent: context.read<AgentRepository>(),
              )..preload(),
              lazy: false,
            ),
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
