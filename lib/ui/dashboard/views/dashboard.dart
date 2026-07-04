import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pico_view/pico_view.dart';

import '../../../../data/repositories/module_repository.dart';
import '../../../../data/services/pico_view_service.dart';
import '../../../../data/services/window_service.dart';
import '../../../../domain/models/app_config.dart';
import '../../../../extensions/loggable.dart';
import '../../../../l10n/app_localizations.dart';
import '../../settings/cubit/app_config_cubit.dart';
import '../../widgets/background_view.dart';
import '../cubit/dashboard_cubit.dart';
import 'dashboard_config_panel.dart';
import 'dashboard_lcd_view.dart';

/// Window size when only the LCD preview is shown (settings collapsed).
const Size kDashboardCompactSize = Size(400, 400);

/// Window size when the module settings panel is expanded below the LCD.
const Size kDashboardExpandedSize = Size(400, 720);

/// Gaussian blur applied to the LCD-area backdrop.
const double _kBackdropBlurSigma = 16;

/// Translucent dark scrim over the blurred backdrop.
const Color _kBackdropScrim = Color(0x40000000);

/// Semi-transparent circular backing for the page-navigation chevrons.
final ButtonStyle _chevronButtonStyle = IconButton.styleFrom(
  backgroundColor: Colors.black.withValues(alpha: 0.2),
);

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with Loggable {
  @override
  String get logIdentifier => '[Dashboard]';

  /// The app-wide pico_view handle (owned by a RepositoryProvider); this widget
  /// drives its open/lifecycle but does not dispose it.
  late final PicoViewService _service = context.read<PicoViewService>();

  /// Whether the module settings panel (and the expanded window) is shown.
  bool _settingsOpen = false;

  /// Re-applies the saved backlight level every time the panel (re)connects.
  StreamSubscription<PicoLinkState>? _linkSub;

  @override
  void initState() {
    super.initState();
    // The device connects asynchronously (LINK_STATE_CONNECTED arrives after
    // attestation), so push the saved brightness on each connect.
    _linkSub = _service.linkStates.listen((state) {
      if (state == PicoLinkState.connected) _applyBrightness();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyWindowSize(kDashboardCompactSize);
      _openDevice();
    });
  }

  /// Send the currently-saved LCD brightness to the device.
  void _applyBrightness() {
    if (!mounted) return;
    _service.setBrightness(
      context.read<AppConfigCubit>().state.lcdBrightness,
    );
  }

  /// Resize the window so the Flutter *content area* gets [contentSize].
  ///
  /// On Windows and macOS, `window_manager`'s set/get size operate on the outer
  /// window rect (Win32 window rect / `NSWindow.frame`), so the native title bar
  /// and borders shrink the content area, leaving it shorter than requested.
  /// Measure the current chrome (outer − content) and add it back. Linux sizes
  /// the content directly (`gtk_window_resize`), so it's skipped there.
  Future<void> _applyWindowSize(Size contentSize) async {
    if (kIsWeb) return;
    var target = contentSize;
    final platform = defaultTargetPlatform;
    final needsChrome =
        platform == TargetPlatform.windows || platform == TargetPlatform.macOS;
    if (needsChrome && mounted) {
      final content = MediaQuery.sizeOf(context);
      final outer = await WindowService.getSize();
      target = Size(
        contentSize.width + (outer.width - content.width),
        contentSize.height + (outer.height - content.height),
      );
    }
    await WindowService.setSize(target);
  }

  /// Show/hide the settings panel and grow/shrink the window to match.
  ///
  /// when opening we grow the window first, then reveal the panel; when closing
  /// we hide the panel first, then shrink the window.
  Future<void> _toggleSettings() async {
    final open = !_settingsOpen;
    try {
      if (open) {
        await _applyWindowSize(kDashboardExpandedSize);
        if (!mounted) return;
        setState(() => _settingsOpen = true);
      } else {
        setState(() => _settingsOpen = false);
        await _applyWindowSize(kDashboardCompactSize);
      }
    } catch (e, s) {
      logWarning('failed to resize window', error: e, stackTrace: s);
    }
  }

  /// Bring up the native bridge and open the LCD.
  void _openDevice() {
    try {
      _service.init();
      _service.open();
    } on PicoViewUnauthorizedException catch (e, s) {
      logWarning(
        'pico_view rejected unauthorized device',
        error: e,
        stackTrace: s,
      );
      _showUnauthorizedSnackBar();
    } on PicoViewException catch (e, s) {
      logWarning('pico_view open failed', error: e, stackTrace: s);
      _showOpenFailedSnackBar();
    } catch (e, s) {
      logError('pico_view init/open error', error: e, stackTrace: s);
      _showOpenFailedSnackBar();
    }
  }

  /// Notify the user that the connected display failed the genuine-hardware
  /// check.
  void _showUnauthorizedSnackBar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).picoViewUnauthorized),
        duration: const Duration(days: 1),
        showCloseIcon: true,
      ),
    );
  }

  /// Notify the user that the LCD couldn't be opened, offering a retry.
  void _showOpenFailedSnackBar() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).picoViewOpenFailed),
        duration: const Duration(days: 1),
        showCloseIcon: true,
        action: SnackBarAction(
          label: AppLocalizations.of(context).retry,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            _openDevice();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    // The controller is owned by the RepositoryProvider, not this widget.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final modules = context.read<ModuleRepository>();

    final scaffold = Scaffold(
      body: Stack(
        children: [
          // Reveal the settings panel only once the window has actually grown
          // taller than the compact size.
          LayoutBuilder(
            builder: (context, constraints) {
              final showPanel =
                  _settingsOpen &&
                  constraints.maxHeight > kDashboardCompactSize.height;
              return Column(
                children: [
                  _buildLcdArea(context, cubit, modules),
                  if (showPanel) ...[
                    const Divider(height: 1),
                    const Expanded(child: DashboardConfigPanel()),
                  ],
                ],
              );
            },
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: AppLocalizations.of(context).settings,
              icon: Icon(_settingsOpen ? Icons.close : Icons.settings),
              onPressed: _toggleSettings,
            ),
          ),
        ],
      ),
    );

    final content = kIsWeb
        ? _WebFrame(
            size: _settingsOpen
                ? kDashboardExpandedSize
                : kDashboardCompactSize,
            child: scaffold,
          )
        : scaffold;

    // Push brightness changes to the panel as soon as they're saved.
    return BlocListener<AppConfigCubit, AppConfig>(
      listenWhen: (prev, curr) => prev.lcdBrightness != curr.lcdBrightness,
      listener: (context, config) =>
          _service.setBrightness(config.lcdBrightness),
      child: content,
    );
  }

  /// The LCD preview block: padding, the round mirror, and the page chevrons.
  Widget _buildLcdArea(
    BuildContext context,
    DashboardCubit cubit,
    ModuleRepository modules,
  ) {
    // A soft drop shadow seats the round mirror on the blurred backdrop.
    final center = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(180),
        child: PicoView(
          controller: _service.controller,
          maxFps: 25,
          child: const DashboardLcdView(),
        ),
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRect(
            child: Transform.scale(
              scale: 1.3,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: _kBackdropBlurSigma,
                  sigmaY: _kBackdropBlurSigma,
                  tileMode: TileMode.clamp,
                ),
                child: BlocBuilder<AppConfigCubit, AppConfig>(
                  buildWhen: (prev, curr) =>
                      prev.backgroundPath != curr.backgroundPath,
                  builder: (context, config) =>
                      BackgroundView(path: config.backgroundPath),
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: _kBackdropScrim)),
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: BlocBuilder<DashboardCubit, DashboardState>(
            buildWhen: (prev, curr) =>
                prev.currentPage != curr.currentPage ||
                prev.enabledItems != curr.enabledItems,
            builder: (context, state) {
              final count = modules.pages(state.items).length;

              // Without at least two enabled pages there are no neighbours to show.
              if (count < 2) {
                return Center(child: center);
              }

              // The LCD is round, so the bottom-left and bottom-right corners
              // of its bounding box are empty.
              return Center(
                child: Stack(
                  children: [
                    center,
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left),
                        iconSize: 24,
                        style: _chevronButtonStyle,
                        onPressed: cubit.prevPage,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        iconSize: 24,
                        style: _chevronButtonStyle,
                        onPressed: cubit.nextPage,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Centers the dashboard at its fixed desktop size on a transparent backdrop.
class _WebFrame extends StatelessWidget {
  const _WebFrame({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: size.width,
        height: size.height,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 8,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
