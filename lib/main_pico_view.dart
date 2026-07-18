/// A minimal, self-contained `pico_view` example: the classic Flutter counter,
/// styled for the round ~360×360 panel and mirrored to it via [PicoView].
///
/// Run with the app's usual native-assets setup:
///
/// ```sh
/// flutter config --enable-native-assets
/// flutter run -d linux -t lib/main_pico_view.dart
/// ```
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pico_view/pico_view.dart';

import 'ui/widgets/panel_text.dart';
import 'ui/widgets/panel_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = PicoViewController()..init();
  try {
    controller.open(const PicoViewConfig());
    controller.setBrightness(40);
  } on PicoViewException catch (e) {
    debugPrint('pico_view: no panel opened ($e) — running on-screen only');
  }

  runApp(PicoViewDemoApp(controller: controller));
}

class PicoViewDemoApp extends StatelessWidget {
  const PicoViewDemoApp({super.key, required this.controller});

  final PicoViewController controller;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness brightness) => ThemeData(
      brightness: brightness,
      fontFamilyFallback: kCjkFontFallback,
      extensions: const [PanelTheme()],
    );

    return MaterialApp(
      title: 'pico_view demo',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: DemoHome(controller: controller),
    );
  }
}

/// On-screen host: the round panel preview. The [PicoView] both captures its
/// child to the LCD and injects panel touches into it, so this same subtree is
/// what the physical panel shows.
class DemoHome extends StatelessWidget {
  const DemoHome({super.key, required this.controller});

  final PicoViewController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceContainerHighest,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: PicoView(
                  controller: controller,
                  child: const CounterPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
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

        return DecoratedBox(
          decoration: BoxDecoration(color: colors.surfaceContainerHigh),
          child: Padding(
            padding: m.pageInset,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                Material(
                  color: colors.surface.withValues(alpha: m.cardAlpha),
                  borderRadius: BorderRadius.circular(m.cardRadius),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: side * 0.10,
                      vertical: side * 0.03,
                    ),
                    child: Text(
                      '$_count',
                      style: panelFont(
                        side * 0.20,
                        m.weightBold,
                        colors.primary,
                      ),
                    ),
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
