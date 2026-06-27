import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nano_dash/l10n/app_localizations.dart';

import '../../../data/repositories/module_repository.dart';
import '../../../domain/models/dashboard.dart';
import '../cubit/dashboard_cubit.dart';

/// The subtree mirrored onto the LCD: the enabled modules shown one full-screen
/// page at a time, switched with a **short horizontal slide** ([_kSwitchDuration]).
///
/// A swipe (or carousel chevron) to the left advances to the next page and
/// slides the content left; a swipe to the right goes back and slides right.
/// The direction is carried on [DashboardState.forward].
///
/// Page changes flow through [DashboardCubit]: a physical-touch swipe on the
/// panel advances it here, and the on-screen carousel chevrons step it too.
/// Minimum net horizontal travel (logical px) that counts as a page swipe when
/// no fling velocity was measured. Comfortably above [kTouchSlop] so a tap that
/// drifts a little doesn't flip pages.
const double _kSwipeDistance = 5;

/// Duration of the page-switch slide. Kept short on purpose: the SPI panel has
/// no TE sync, so every transitional frame can tear — a brief slide bounds the
/// number of such frames while still softening the switch.
const Duration _kSwitchDuration = Duration(milliseconds: 180);

/// Horizontal slide transition, direction set by [forward].
///
/// [AnimatedSwitcher] hands the outgoing page the same builder with its
/// animation reversed (value 1→0), so we read the status to tell the two pages
/// apart and translate them in opposite directions in lockstep, like a
/// carousel:
///
/// * [forward] (next page) — content slides **left**: the incoming page enters
///   from the right edge (dx 1→0) while the outgoing page exits left (dx 0→-1).
/// * not [forward] (previous page) — content slides **right**: the incoming
///   page enters from the left (dx -1→0) while the outgoing page exits right
///   (dx 0→1).
Widget _slide(
  Widget child,
  Animation<double> animation, {
  required bool forward,
}) {
  return AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, c) {
      final isOutgoing =
          animation.status == AnimationStatus.reverse ||
          animation.status == AnimationStatus.dismissed;
      final double dx;
      if (forward) {
        dx = isOutgoing ? animation.value - 1 : 1 - animation.value;
      } else {
        dx = isOutgoing ? 1 - animation.value : animation.value - 1;
      }
      return FractionalTranslation(translation: Offset(dx, 0), child: c);
    },
  );
}

class DashboardLcdView extends StatelessWidget {
  const DashboardLcdView({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = context.read<ModuleRepository>();

    return BlocBuilder<DashboardCubit, DashboardState>(
      // Rebuild on a page switch, on enable/disable, and on a live settings
      // edit to the visible page.
      buildWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage ||
          prev.enabledItems != curr.enabledItems,
      builder: (context, state) {
        final pages = modules.pages(state.items);
        if (pages.isEmpty) {
          return const _EmptyLcd();
        }
        final count = pages.length;
        final cur = state.currentPage.clamp(0, count - 1);
        final item = pages[cur];

        Widget view = AnimatedSwitcher(
          duration: _kSwitchDuration,
          transitionBuilder: (child, animation) =>
              _slide(child, animation, forward: state.forward),
          child: KeyedSubtree(
            key: ValueKey<String>('${item.moduleId}#$cur'),
            child: _buildModule(context, modules, item),
          ),
        );

        // With more than one module, a horizontal swipe steps pages. Restrict
        // it to touch/stylus (the panel's input).
        if (count > 1) {
          view = RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              HorizontalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    HorizontalDragGestureRecognizer
                  >(
                    () => HorizontalDragGestureRecognizer(
                      supportedDevices: const {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.stylus,
                      },
                    ),
                    (recognizer) {
                      // Net horizontal travel of the in-flight drag. We need this
                      // because a janky module starves pointer-move delivery, and the velocity
                      // tracker then can't classify the gesture as a fling —
                      // primaryVelocity comes back 0. Distance survives that, so we
                      // fall back to it. build() isn't called mid-drag (buildWhen
                      // only fires on page/enable changes), so this closure variable
                      // lives for exactly one drag.
                      var dragDx = 0.0;
                      recognizer.onStart = (details) => dragDx = 0.0;
                      recognizer.onUpdate = (details) =>
                          dragDx += details.primaryDelta ?? 0;
                      recognizer.onEnd = (details) =>
                          _onSwipe(context, details, dragDx);
                    },
                  ),
            },
            child: view,
          );
        }

        // Shared room background, painted once below the page switcher. Modules
        // render transparently on top (the LCD subtree composites over this), so
        // a page switch only transitions the module while the background stays static.
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/bg.png', fit: BoxFit.cover),
            view,
          ],
        );
      },
    );
  }

  /// A swipe steps one page (wrapping): left → next (slide left), right →
  /// previous (slide right).
  void _onSwipe(BuildContext context, DragEndDetails details, double dragDx) {
    final velocity = details.primaryVelocity ?? 0;
    // Leftward is negative for both signals.
    final double direction;
    if (velocity != 0) {
      direction = velocity;
    } else if (dragDx.abs() >= _kSwipeDistance) {
      direction = dragDx;
    } else {
      return;
    }
    final cubit = context.read<DashboardCubit>();
    direction < 0 ? cubit.nextPage() : cubit.prevPage();
  }

  Widget _buildModule(
    BuildContext context,
    ModuleRepository modules,
    DashboardItemConfig item,
  ) {
    final module = modules.byId(item.moduleId);
    if (module == null) {
      return const ColoredBox(color: Colors.black);
    }
    return module.build(context, item.settings);
  }
}

class _EmptyLcd extends StatelessWidget {
  const _EmptyLcd();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.dashboard_customize,
              color: Colors.white54,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.dashboardEmpty,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.dashboardEmptyHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
