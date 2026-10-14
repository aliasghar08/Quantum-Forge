import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quantum_forge/core/services/auth_service.dart';
import 'package:quantum_forge/core/services/local_auth_service.dart';
import 'package:quantum_forge/core/services/reaction_repository.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/core/widgets/adsense_banner_web.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_library_mobile_view.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/screens/history_screen.dart';

class _FakeReactionRepository implements ReactionRepository {
  @override
  Future<String> createReaction(Map<String, dynamic> reactionData) async => 'fake-id';

  @override
  Stream<ReactionStatusResponse> watchReaction(String reactionId) => const Stream.empty();

  @override
  Future<ReactionStatusResponse?> getReaction(String reactionId) async => null;

  @override
  Future<ReactionStatusResponse?> findCachedTemplateReaction(String templateId, Map<String, dynamic> settingsMap) async => null;

  @override
  Future<void> updateReaction(String reactionId, Map<String, dynamic> fields) async {}

  @override
  Future<List<ReactionStatusResponse>> listReactions(String userId) async => [];

  @override
  Future<void> deleteReaction(String reactionId) async {}

  @override
  Future<void> saveCompletedReaction(ReactionStatusResponse response, [String? userId]) async {}
}

class _UnauthenticatedAuthService extends LocalAuthService {
  @override
  Future<bool> isAuthenticated() async => false;
}

void main() {
  group('AdSenseBannerWeb Widget Unit & Layout Tests', () {
    testWidgets('returns SizedBox.shrink when isProUser is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdSenseBannerWeb(
              isProUser: true,
              isSignedIn: false,
            ),
          ),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any((box) => box.width == 0.0 && box.height == 0.0),
        isTrue,
      );
      expect(find.text('ADVERTISEMENT'), findsNothing);
    });

    testWidgets('returns SizedBox.shrink when isSignedIn is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdSenseBannerWeb(
              isProUser: false,
              isSignedIn: true,
            ),
          ),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any((box) => box.width == 0.0 && box.height == 0.0),
        isTrue,
      );
      expect(find.text('ADVERTISEMENT'), findsNothing);
    });

    testWidgets('renders cleanly on mobile viewport (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdSenseBannerWeb(
              isProUser: false,
              isSignedIn: false,
              forceRenderInTest: true,
              placement: 'test_mobile',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('renders cleanly on extremely narrow mobile screen (320x600)', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdSenseBannerWeb(
              isProUser: false,
              isSignedIn: false,
              forceRenderInTest: true,
              placement: 'test_narrow',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('dismiss button collapses banner to avoid blocking visuals', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdSenseBannerWeb(
              isProUser: false,
              isSignedIn: false,
              forceRenderInTest: true,
              placement: 'test_dismiss',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('ADVERTISEMENT'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap dismiss/close icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Banner collapses so visuals are never blocked
      expect(find.text('ADVERTISEMENT'), findsNothing);
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(
        sizedBoxes.any((box) => box.width == 0.0 && box.height == 0.0),
        isTrue,
      );
    });
  });

  group('AdSense Responsive Screen Integrations', () {
    testWidgets('HistoryScreen displays AdSenseBannerWeb in unauthenticated state without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final auth = _UnauthenticatedAuthService();
      final repo = _FakeReactionRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthService>.value(value: auth),
            Provider<ReactionRepository>.value(value: repo),
            ChangeNotifierProvider<ThemeNotifier>(
              create: (_) => ThemeNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HistoryScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('History Requires an Account'), findsOneWidget);
      expect(find.byType(AdSenseBannerWeb), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ReactionLibraryMobileView integrates AdSenseBannerWeb at bottom of list',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final searchCtrl = TextEditingController();
      addTearDown(searchCtrl.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ReactionLibraryMobileView(
            searchController: searchCtrl,
            selectedCategory: null,
            onCategorySelected: (_) {},
            onAddReaction: () {},
            onAutoGenerate: () {},
            onSyncFirebase: () {},
            reactions: kReactionTemplates.take(1).toList(),
            isProUser: false,
            isSignedIn: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AdSenseBannerWeb), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
