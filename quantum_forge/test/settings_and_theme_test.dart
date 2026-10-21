// ============================================================================
// Settings + theme tests
// ----------------------------------------------------------------------------
// The settings model existed but was never registered, so nothing tested it.
// These tests pin persistence, the convenience mutators, clamping, and the
// integrity of every scientific theme preset (all presets must build a valid
// ThemeData and keep plot colours distinguishable).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/app_storage.dart';
import 'package:quantum_forge/core/settings/app_settings_provider.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Off the web `AppStorage` resolves to its in-memory stub, so clearing it
  // gives each test the same blank slate that `setMockInitialValues({})` did.
  setUp(AppStorage.clear);

  group('AppSettings defaults', () {
    test('are sensible for a first run', () {
      const s = AppSettings();
      expect(s.isCompactMode, isFalse);
      expect(s.showTooltips, isTrue);
      expect(s.defaultElement, 'C');
      expect(s.defaultExportFormat, ExportFormat.xyz);
      expect(s.exportPrecision, 5);
      expect(s.includeTitleLine, isTrue);
      expect(s.atomScale, AtomScale.ballAndStick);
      expect(s.avogadroBridgeEnabled, isTrue);
      expect(s.cleanUrlAfterImport, isTrue);
      expect(s.density, 1.0);
    });

    test('compact mode is reflected in the density helper', () {
      const s = AppSettings(isCompactMode: true);
      expect(s.density, lessThan(1.0));
      expect(s.gap(20), lessThan(20));
      expect(const AppSettings().gap(20), 20);
    });

    test('copyWith leaves untouched fields alone', () {
      const base = AppSettings(defaultElement: 'N', exportPrecision: 7);
      final updated = base.copyWith(isCompactMode: true);
      expect(updated.defaultElement, 'N');
      expect(updated.exportPrecision, 7);
      expect(updated.isCompactMode, isTrue);
    });

    test('equality and hashCode cover every field', () {
      const a = AppSettings();
      const b = AppSettings();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == const AppSettings(showTooltips: false), isFalse);
      expect(a == const AppSettings(exportPrecision: 4), isFalse);
      expect(a == const AppSettings(bridgeTarget: BridgeTarget.localhost), isFalse);
    });
  });

  group('bridge endpoint resolution', () {
    test('production and localhost have defaults', () {
      const prod = AppSettings(bridgeTarget: BridgeTarget.production);
      const dev = AppSettings(bridgeTarget: BridgeTarget.localhost);
      expect(prod.bridgeBaseUrl, 'https://quantom-forge.web.app');
      expect(dev.bridgeBaseUrl, 'http://localhost:8080');
    });

    test('a custom URL wins and trailing slashes are trimmed', () {
      const custom = AppSettings(
        bridgeTarget: BridgeTarget.custom,
        customBaseUrl: 'https://chem.example.org/qf/  ',
      );
      expect(custom.bridgeBaseUrl, 'https://chem.example.org/qf');
    });

    test('an empty custom URL falls back rather than producing a broken link', () {
      const empty = AppSettings(
        bridgeTarget: BridgeTarget.custom,
        customBaseUrl: '   ',
      );
      expect(empty.bridgeBaseUrl, 'https://quantom-forge.web.app');
    });
  });

  group('export format metadata', () {
    test('every format has a distinct extension and a MIME type', () {
      final extensions = ExportFormat.values.map((f) => f.extension).toSet();
      expect(extensions, hasLength(ExportFormat.values.length));
      for (final format in ExportFormat.values) {
        expect(format.mimeType, startsWith('chemical/'));
        expect(format.label, isNotEmpty);
        expect(format.shortLabel, isNotEmpty);
      }
    });

    test('CJSON is flagged as the Avogadro-native format', () {
      expect(ExportFormat.cjson.isAvogadroNative, isTrue);
      expect(ExportFormat.xyz.isAvogadroNative, isFalse);
    });

    test('parsing tolerates both enum names and short labels', () {
      expect(ExportFormat.fromName('cjson'), ExportFormat.cjson);
      expect(ExportFormat.fromName('CJSON'), ExportFormat.cjson);
      expect(ExportFormat.fromName('SDF'), ExportFormat.sdf);
      expect(ExportFormat.fromName('nonsense'), ExportFormat.xyz);
      expect(ExportFormat.fromName(null), ExportFormat.xyz);
    });
  });

  group('AppSettingsNotifier persistence', () {
    test('applies changes and writes them to disk', () async {
      final notifier = AppSettingsNotifier(initialSettings: const AppSettings());

      notifier.setCompactMode(true);
      notifier.setDefaultElement('S');
      notifier.setExportPrecision(7);
      notifier.setBridgeTarget(BridgeTarget.localhost);
      notifier.setAtomScale(AtomScale.spaceFilling);

      expect(notifier.settings.isCompactMode, isTrue);
      expect(notifier.settings.defaultElement, 'S');
      expect(notifier.settings.exportPrecision, 7);

      await notifier.flush();

      final reloaded = AppSettingsNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reloaded.settings.isCompactMode, isTrue);
      expect(reloaded.settings.defaultElement, 'S');
      expect(reloaded.settings.exportPrecision, 7);
      expect(reloaded.settings.bridgeTarget, BridgeTarget.localhost);
      expect(reloaded.settings.atomScale, AtomScale.spaceFilling);
    });

    test('writes queued back-to-back are not lost or reordered', () async {
      // Five setters in a row used to race: each started an independent write
      // and only the first future was awaited, so an older snapshot could land
      // last. The notifier now chains writes instead.
      final notifier = AppSettingsNotifier(initialSettings: const AppSettings());
      notifier.setCompactMode(true);
      notifier.setDefaultElement('S');
      notifier.setExportPrecision(7);
      notifier.setBridgeTarget(BridgeTarget.localhost);
      notifier.setAtomScale(AtomScale.spaceFilling);
      await notifier.flush();

      // AppStorage reads are synchronous and already durable by the time
      // flush() completes, so there is nothing left to await here.
      expect(AppStorage.getString('app_settings_default_element'), 'S');
      expect(AppStorage.getInt('app_settings_export_precision'), 7);
      expect(AppStorage.getBool('app_settings_compact_mode'), isTrue);
      expect(AppStorage.getString('app_settings_atom_scale'), 'spaceFilling');
      expect(AppStorage.getString('app_settings_bridge_target'), 'localhost');

      // flush() must be idempotent and safe to call when nothing is pending.
      await notifier.flush();
      await notifier.flush();
    });

    test('every field survives a save/reload cycle', () async {
      final notifier = AppSettingsNotifier(initialSettings: const AppSettings());
      notifier.updateSettings((s) => s.copyWith(
            isCompactMode: true,
            reduceMotion: true,
            showTooltips: false,
            defaultElement: 'Cl',
            defaultAutoOptimize: false,
            atomScale: AtomScale.wireframe,
            showBonds: false,
            showHydrogens: false,
            bondTolerance: 1.25,
            defaultExportFormat: ExportFormat.cjson,
            exportPrecision: 3,
            includeTitleLine: false,
            autoSaveIntervalMinutes: 17,
            avogadroBridgeEnabled: false,
            bridgeTarget: BridgeTarget.custom,
            customBaseUrl: 'https://chem.example.org',
            cleanUrlAfterImport: false,
            autoImportDeepLink: false,
          ));
      await notifier.flush();

      final reloaded = AppSettingsNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(reloaded.settings, notifier.settings);
    });

    test('clamps numeric ranges instead of storing nonsense', () {
      final notifier = AppSettingsNotifier(initialSettings: const AppSettings());
      notifier.setExportPrecision(99);
      expect(notifier.settings.exportPrecision, 8);
      notifier.setExportPrecision(-3);
      expect(notifier.settings.exportPrecision, 2);

      notifier.setAutoSaveIntervalMinutes(0);
      expect(notifier.settings.autoSaveIntervalMinutes, 1);
      notifier.setAutoSaveIntervalMinutes(9999);
      expect(notifier.settings.autoSaveIntervalMinutes, 120);
    });

    test('notifies listeners only when something actually changed', () {
      final notifier = AppSettingsNotifier(initialSettings: const AppSettings());
      var notifications = 0;
      notifier.addListener(() => notifications++);

      notifier.setCompactMode(true);
      expect(notifications, 1);
      notifier.setCompactMode(true); // same value — no notification
      expect(notifications, 1);
      notifier.setCompactMode(false);
      expect(notifications, 2);
    });

    test('resetToDefaults restores every field', () {
      final notifier = AppSettingsNotifier(
        initialSettings: const AppSettings(
          isCompactMode: true,
          defaultElement: 'U',
          exportPrecision: 8,
          bridgeTarget: BridgeTarget.localhost,
        ),
      );
      notifier.resetToDefaults();
      expect(notifier.settings, const AppSettings());
    });
  });

  group('scientific theme presets', () {
    test('there are at least seven and ids are unique', () {
      expect(QuantumThemes.all.length, greaterThanOrEqualTo(7));
      final ids = QuantumThemes.all.map((t) => t.id).toSet();
      expect(ids, hasLength(QuantumThemes.all.length));
    });

    test('every preset builds a valid ThemeData matching its brightness', () {
      for (final theme in QuantumThemes.all) {
        final data = theme.toThemeData();
        expect(data.brightness, theme.brightness, reason: theme.id);
        expect(data.scaffoldBackgroundColor, theme.scaffold, reason: theme.id);
        expect(data.useMaterial3, isTrue, reason: theme.id);
      }
    });

    test('theme data follows the palette for app bar and inputs', () {
      final dark = QuantumThemes.darkMatter.toThemeData();
      expect(dark.appBarTheme.backgroundColor, QuantumThemes.darkMatter.scaffold);
      final light = QuantumThemes.scientificLight.toThemeData();
      expect(light.brightness, Brightness.light);
      expect(light.appBarTheme.foregroundColor, isNotNull);
    });

    test('light presets report dark text, dark presets report light text', () {
      expect(QuantumThemes.scientificLight.isLight, isTrue);
      expect(QuantumThemes.scientificLight.onPanel.computeLuminance(),
          lessThan(0.5));
      expect(QuantumThemes.darkMatter.isLight, isFalse);
      expect(QuantumThemes.darkMatter.onPanel.computeLuminance(),
          greaterThan(0.5));
    });

    test('every preset has at least six distinguishable plot colours', () {
      for (final theme in QuantumThemes.all) {
        expect(theme.plotPalette.length, greaterThanOrEqualTo(6),
            reason: theme.id);
        expect(theme.plotPalette.toSet().length, theme.plotPalette.length,
            reason: '${theme.id} has duplicate plot colours');
      }
    });

    test('plotColor wraps around instead of throwing', () {
      final theme = QuantumThemes.journalMono;
      expect(theme.plotColor(0), theme.plotPalette[0]);
      expect(
        theme.plotColor(theme.plotPalette.length),
        theme.plotPalette[0],
      );
    });

    test('every preset has a description and a family for the settings UI', () {
      for (final theme in QuantumThemes.all) {
        expect(theme.description.length, greaterThan(30), reason: theme.id);
        expect(theme.family, isNotEmpty, reason: theme.id);
        expect(theme.label, isNotEmpty, reason: theme.id);
      }
    });

    test('presets are grouped into more than one family', () {
      expect(QuantumThemes.byFamily.keys.length, greaterThan(1));
    });

    test('byId falls back to the default instead of throwing', () {
      expect(QuantumThemes.byId('electron_cloud').id, 'electron_cloud');
      expect(QuantumThemes.byId('does-not-exist').id, QuantumThemes.darkMatter.id);
      expect(QuantumThemes.byId(null.toString()).id, QuantumThemes.darkMatter.id);
    });

    test('the enum exposes every preset exactly once', () {
      expect(AppTheme.values, hasLength(QuantumThemes.all.length));
      for (final appTheme in AppTheme.values) {
        expect(appTheme.preset.id, appTheme.id);
        expect(appTheme.label, isNotEmpty);
        expect(AppTheme.fromId(appTheme.id), appTheme);
      }
      expect(AppTheme.fromId('bogus'), AppTheme.darkMatter);
      expect(AppTheme.fromId(null), AppTheme.darkMatter);
    });
  });

  group('ThemeNotifier', () {
    test('starts at the default when constructed with an explicit theme', () {
      final notifier = ThemeNotifier(initialTheme: AppTheme.electronCloud);
      expect(notifier.currentTheme, AppTheme.electronCloud);
      expect(notifier.palette.id, 'electron_cloud');
      expect(notifier.isInitialized, isTrue);
    });

    test('setTheme notifies and persists', () async {
      AppStorage.clear();
      final notifier = ThemeNotifier(initialTheme: AppTheme.darkMatter);
      var notifications = 0;
      notifier.addListener(() => notifications++);

      await notifier.setTheme(AppTheme.spectroscopy);
      expect(notifier.currentTheme, AppTheme.spectroscopy);
      expect(notifications, 1);

      await notifier.setTheme(AppTheme.spectroscopy); // no-op
      expect(notifications, 1);

      expect(AppStorage.getString(ThemeNotifier.storageKey), 'spectroscopy');
    });

    test('restores the persisted theme on construction', () {
      AppStorage.clear();
      AppStorage.setString(ThemeNotifier.storageKey, 'journal_mono');
      // AppStorage is synchronous, so the constructor has already restored the
      // value by the time it returns — no microtask drain needed.
      final notifier = ThemeNotifier();
      expect(notifier.currentTheme, AppTheme.journalMono);
      expect(notifier.isInitialized, isTrue);
    });

    test('cycleTheme walks every preset and wraps around', () async {
      final notifier = ThemeNotifier(initialTheme: AppTheme.values.last);
      await notifier.cycleTheme();
      expect(notifier.currentTheme, AppTheme.values.first);
    });

    test('reset returns to the factory default', () async {
      final notifier = ThemeNotifier(initialTheme: AppTheme.neonSynth);
      await notifier.reset();
      expect(notifier.currentTheme, AppTheme.darkMatter);
    });

    test('an unknown stored id falls back without throwing', () {
      AppStorage.clear();
      AppStorage.setString(ThemeNotifier.storageKey, 'not-a-theme');
      final notifier = ThemeNotifier();
      expect(notifier.currentTheme, AppTheme.darkMatter);
    });

    test('setThemeById accepts various string formats and persists', () async {
      AppStorage.clear();
      final notifier = ThemeNotifier();
      await notifier.setThemeById('neonSynth');
      expect(notifier.currentTheme, AppTheme.neonSynth);
      expect(AppStorage.getString(ThemeNotifier.storageKey), 'neon_synth');

      await notifier.setThemeById('scientific-light');
      expect(notifier.currentTheme, AppTheme.scientificLight);

      await notifier.setThemeById('Journal Mono');
      expect(notifier.currentTheme, AppTheme.journalMono);
    });
  });

  group('robust theme parsing & fuzzy lookup', () {
    test('AppTheme.fromId resolves camelCase enum names', () {
      expect(AppTheme.fromId('darkMatter'), AppTheme.darkMatter);
      expect(AppTheme.fromId('quantumBlue'), AppTheme.quantumBlue);
      expect(AppTheme.fromId('neonSynth'), AppTheme.neonSynth);
      expect(AppTheme.fromId('electronCloud'), AppTheme.electronCloud);
      expect(AppTheme.fromId('spectroscopy'), AppTheme.spectroscopy);
      expect(AppTheme.fromId('scientificLight'), AppTheme.scientificLight);
      expect(AppTheme.fromId('journalMono'), AppTheme.journalMono);
    });

    test('AppTheme.fromId resolves kebab-case and display labels', () {
      expect(AppTheme.fromId('neon-synth'), AppTheme.neonSynth);
      expect(AppTheme.fromId('Neon Synth'), AppTheme.neonSynth);
      expect(AppTheme.fromId('scientific-light'), AppTheme.scientificLight);
      expect(AppTheme.fromId('Scientific Light'), AppTheme.scientificLight);
      expect(AppTheme.fromId('journal-mono'), AppTheme.journalMono);
      expect(AppTheme.fromId('Journal Mono'), AppTheme.journalMono);
    });

    test('AppTheme.fromId resolves numeric indexes', () {
      for (var i = 0; i < AppTheme.values.length; i++) {
        expect(AppTheme.fromId('$i'), AppTheme.values[i]);
      }
    });

    test('QuantumThemes.byId matches AppTheme.fromId across all formats', () {
      final formats = [
        'dark_matter', 'darkMatter', 'Dark Matter', '0',
        'quantum_blue', 'quantumBlue', 'Quantum Blue', '1',
        'neon_synth', 'neonSynth', 'neon-synth', 'Neon Synth', '2',
        'electron_cloud', 'electronCloud', 'electron-cloud', 'Electron Cloud', '3',
        'spectroscopy', 'Spectroscopy', '4',
        'scientific_light', 'scientificLight', 'scientific-light', 'Scientific Light', '5',
        'journal_mono', 'journalMono', 'journal-mono', 'Journal Mono', '6',
      ];
      for (final format in formats) {
        expect(QuantumThemes.byId(format).id, AppTheme.fromId(format).id);
      }
    });
  });

  group('Material 3 theme contrast and complete styles', () {
    test('every preset provides high-contrast onPrimary and onSecondary', () {
      for (final theme in QuantumThemes.all) {
        final themeData = theme.toThemeData();
        final scheme = themeData.colorScheme;

        expect(scheme.primary, theme.accent, reason: theme.id);
        expect(scheme.onPrimary, theme.onAccent, reason: theme.id);

        final primaryLum = scheme.primary.computeLuminance();
        final onPrimaryLum = scheme.onPrimary.computeLuminance();
        final contrastDelta = (primaryLum - onPrimaryLum).abs();
        expect(contrastDelta, greaterThan(0.2),
            reason: '${theme.id} onPrimary lacks contrast with primary');

        expect(scheme.surface, theme.panel, reason: theme.id);
        expect(scheme.onSurface, theme.textPrimary, reason: theme.id);
        expect(scheme.onSurfaceVariant, theme.textSecondary, reason: theme.id);
        expect(scheme.surfaceContainer, theme.panel, reason: theme.id);
        expect(scheme.surfaceContainerHigh, theme.panelAlt, reason: theme.id);
      }
    });

    test('themeData defines button and tab themes with correct foregrounds', () {
      for (final theme in QuantumThemes.all) {
        final data = theme.toThemeData();
        expect(data.elevatedButtonTheme.style, isNotNull, reason: theme.id);
        expect(data.filledButtonTheme.style, isNotNull, reason: theme.id);
        expect(data.tabBarTheme.indicatorColor, theme.accent, reason: theme.id);
      }
    });

    test('isDark and isLight are strictly opposite', () {
      for (final theme in QuantumThemes.all) {
        expect(theme.isDark, !theme.isLight, reason: theme.id);
      }
    });

    test('copyWith produces identical instance by default and overrides correctly', () {
      final original = QuantumThemes.spectroscopy;
      final copy = original.copyWith();
      expect(copy, equals(original));

      final modified = original.copyWith(label: 'Custom Spec');
      expect(modified.label, 'Custom Spec');
      expect(modified.accent, original.accent);
    });
  });

  testWidgets('ThemeNotifier.paletteOf safely returns darkMatter when un-provided',
      (tester) async {
    late QuantumTheme observedPalette;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          observedPalette = ThemeNotifier.paletteOf(context);
          return const SizedBox.shrink();
        },
      ),
    );
    expect(observedPalette.id, QuantumThemes.darkMatter.id);
  });
}
