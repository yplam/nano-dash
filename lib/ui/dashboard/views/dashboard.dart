import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/module_repository.dart';
import '../cubit/dashboard_cubit.dart';
import '../widgets/dashboard_config_panel.dart';
import '../widgets/dashboard_lcd_view.dart';

/// On-screen size of the mirrored LCD subtree, in logical pixels.
///
/// While the `pico_view` package is out, there's no device config to drive the
/// geometry, so we render the subtree at the panel's native landscape size.
/// Restore [PicoViewConfig]-driven sizing here when the package comes back.
const double _kLcdWidth = 360;
const double _kLcdHeight = 360;

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DashboardCubit>();
    final modules = context.read<ModuleRepository>();

    // Mirrored subtree. With pico_view gone it only renders on-screen; the
    // native bridge that flushed these frames to the LCD will be wired back in
    // when the package returns.
    final center = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(180),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(180),
        child: const SizedBox(
          width: _kLcdWidth,
          height: _kLcdHeight,
          child: DashboardLcdView(),
        ),
      ),
    );
    // The voice engine is a config-only capability with no page of its own:
    // disabling the voice module from anywhere must tear the engine down (and
    // drop the agent out of conversation mode), regardless of which page — if
    // any — is currently visible. Handle it centrally here rather than in the
    // chatbot view, which may not be mounted.
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

                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        iconSize: 24,
                        onPressed: cubit.prevPage,
                      ),
                      const SizedBox(width: 4),
                      center,
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        iconSize: 24,
                        onPressed: cubit.nextPage,
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
