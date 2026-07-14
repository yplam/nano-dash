import 'package:flutter_test/flutter_test.dart';
import 'package:nano_dash/domain/models/dashboard.dart';

void main() {
  group('DashboardItemConfig JSON', () {
    test('round-trips the tri-state visibility', () {
      for (final v in ModuleVisibility.values) {
        final config = DashboardItemConfig(
          moduleId: 'weather',
          visibility: v,
          settings: const {'city': 'Tokyo'},
        );
        final restored = DashboardItemConfig.fromJson(config.toJson());
        expect(restored.visibility, v);
        expect(restored.moduleId, 'weather');
        expect(restored.settings, {'city': 'Tokyo'});
      }
    });

    test('migrates a legacy enabled:true config to carousel', () {
      final restored = DashboardItemConfig.fromJson({
        'moduleId': 'weather',
        'enabled': true,
        'settings': const {},
      });
      expect(restored.visibility, ModuleVisibility.carousel);
      expect(restored.enabled, isTrue);
      expect(restored.assistantVisible, isTrue);
    });

    test('migrates a legacy enabled:false config to off', () {
      final restored = DashboardItemConfig.fromJson({
        'moduleId': 'markets',
        'enabled': false,
      });
      expect(restored.visibility, ModuleVisibility.off);
      expect(restored.enabled, isFalse);
      expect(restored.assistantVisible, isFalse);
    });

    test('an unknown visibility name falls back to off', () {
      final restored = DashboardItemConfig.fromJson({
        'moduleId': 'x',
        'visibility': 'bogus',
      });
      expect(restored.visibility, ModuleVisibility.off);
    });

    test('assistant-only is visible to the assistant but not the carousel', () {
      const config = DashboardItemConfig(
        moduleId: 'markets',
        visibility: ModuleVisibility.assistant,
      );
      expect(config.enabled, isFalse);
      expect(config.assistantVisible, isTrue);
    });
  });
}
