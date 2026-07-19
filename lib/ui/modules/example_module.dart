import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/panel_text.dart';
import '../widgets/panel_theme.dart';

/// A minimal, self-contained `pico_view` example: the classic Flutter counter,
/// styled for the round ~360×360 panel.
class ExampleModule extends Module {
  const ExampleModule();

  static const String kId = 'example';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.add_circle_outline;

  @override
  String title(AppLocalizations l10n) => l10n.moduleExampleTitle;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const _CounterPage();
}

class _CounterPage extends StatefulWidget {
  const _CounterPage();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int _count = 0;

  void _increment() => setState(() => _count++);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final m = PanelTheme.metricsOf(context, side, shape: PanelShape.square);
        final buttonSize = side * 0.20;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(side * 0.04),
            child: SizedBox(
              width: side * 0.76,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(side * 0.09),
                  border: Border.all(
                    color: colors.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: side * 0.07,
                    vertical: side * 0.06,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Button tapped',
                        style: panelFont(
                          m.fontMd,
                          m.weightMedium,
                          colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: m.gap),
                      Text(
                        '$_count',
                        style: panelFont(
                          side * 0.20,
                          m.weightBold,
                          colors.primary,
                        ),
                      ),
                      SizedBox(height: m.gap * 1.5),
                      _RoundButton(
                        size: buttonSize,
                        color: colors.primary,
                        onColor: colors.onPrimary,
                        onTap: _increment,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.color,
    required this.onColor,
    required this.onTap,
  });

  final double size;
  final Color color;
  final Color onColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.add, size: size * 0.5, color: onColor),
        ),
      ),
    );
  }
}
