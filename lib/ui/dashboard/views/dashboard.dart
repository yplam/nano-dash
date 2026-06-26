import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pico_view/pico_view.dart';

import '../../../../data/repositories/module_repository.dart';
import '../../../../extensions/loggable.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/dashboard_cubit.dart';
import 'dashboard_config_panel.dart';
import 'dashboard_lcd_view.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with Loggable {
  @override
  String get logIdentifier => '[Dashboard]';

  final PicoViewController _controller = PicoViewController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDevice());
  }

  /// Bring up the native bridge and open the LCD.
  void _openDevice() {
    try {
      _controller.init();
      _controller.open(const PicoViewConfig());
    } on PicoViewException catch (e, s) {
      logWarning('pico_view open failed', error: e, stackTrace: s);
      _showOpenFailedSnackBar();
    } catch (e, s) {
      logError('pico_view init/open error', error: e, stackTrace: s);
      _showOpenFailedSnackBar();
    }
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final modules = context.read<ModuleRepository>();

    final center = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(180),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(180),
        child: PicoView(
          controller: _controller,
          maxFps: 25,
          child: const DashboardLcdView(),
        ),
      ),
    );
    return Scaffold(
      body: Column(
        children: [
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
                          onPressed: cubit.prevPage,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right),
                          iconSize: 24,
                          onPressed: cubit.nextPage,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: DashboardConfigPanel()),
        ],
      ),
    );
  }
}
