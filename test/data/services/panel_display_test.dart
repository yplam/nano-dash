import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/data/services/agent_tools.dart';
import 'package:nano_dash/data/services/panel_display_controller.dart';

void main() {
  late PanelDisplayController display;

  setUp(() => display = PanelDisplayController());
  tearDown(() => display.dispose());

  test('show_on_screen shows a currently-displayable module transiently', () async {
    display.displayable = {'weather', 'clock'};
    final shown = <PanelShowRequest>[];
    display.requests.listen(shown.add);

    final tool = buildDisplayTool(
      display,
      modules: const {'weather': 'Weather', 'clock': 'Clock'},
    );
    final result = await tool.run({'module': 'weather'});

    expect(result, contains('"shown":"weather"'));
    await Future<void>.delayed(Duration.zero);
    expect(shown, [(moduleId: 'weather', sticky: false)]);
  });

  test('show_on_screen declines a module that is not displayable', () async {
    display.displayable = {'clock'};
    final shown = <PanelShowRequest>[];
    display.requests.listen(shown.add);

    final tool = buildDisplayTool(
      display,
      modules: const {'weather': 'Weather', 'clock': 'Clock'},
    );
    final result = await tool.run({'module': 'weather'});

    expect(result, startsWith('Error:'));
    expect(result, contains('clock')); // lists what is available
    await Future<void>.delayed(Duration.zero);
    expect(shown, isEmpty);
  });

  test('goTo emits a sticky request', () async {
    final shown = <PanelShowRequest>[];
    display.requests.listen(shown.add);

    display.goTo('timer');

    await Future<void>.delayed(Duration.zero);
    expect(shown, [(moduleId: 'timer', sticky: true)]);
  });
}
