import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/auth_service.dart';
import 'package:quantum_forge/core/services/local_auth_service.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_card_widget.dart';
import 'package:quantum_forge/screens/auth_screen.dart';

void main() {
  group('ReactionCardWidget History Support', () {
    testWidgets('renders reaction card with barrier badge and action buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool loadCalled = false;
      bool deleteCalled = false;

      const template = ReactionTemplate(
        id: 'med-aspirin-01',
        name: 'Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation',
        iupacName: 'Transformer-MP-TS • 12 frames',
        description: 'Converged trajectory with 12 frames and activation barrier of 18.20 kcal/mol.',
        category: ReactionCategory.organometallic,
        reactantXyz: '',
        productXyz: '',
        referenceEa: 15.45,
        doi: '',
        journalRef: '2026-10-26 19:41:20',
        tags: ['Transformer-MP-TS', '12 frames', 'cloud', 'converged'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                height: 255,
                child: ReactionCardWidget(
                  template: template,
                  onLoad: () => loadCalled = true,
                  onDelete: () => deleteCalled = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aspirin (Acetylsalicylic Acid) Synthesis & COX Acetylation'), findsOneWidget);
      expect(find.textContaining('kcal·mol⁻¹'), findsOneWidget);
      expect(find.text('Load'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.text('Load'));
      expect(loadCalled, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(deleteCalled, isTrue);
    });

    testWidgets('custom onTap is triggered when card is clicked', (tester) async {
      bool tapCalled = false;

      const template = ReactionTemplate(
        id: 'rxn-tap-test',
        name: 'LST completed successfully (121 frames)',
        iupacName: 'tx1-fastapi • 121 frames',
        description: 'Completed reaction run.',
        category: ReactionCategory.thermal,
        reactantXyz: '',
        productXyz: '',
        referenceEa: 67.42,
        doi: '',
        journalRef: '2026-10-23 21:40:53',
        tags: ['tx1-fastapi', '121 frames', 'cloud'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 255,
              child: ReactionCardWidget(
                template: template,
                onLoad: () {},
                onTap: () => tapCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('LST completed successfully (121 frames)'));
      expect(tapCalled, isTrue);
    });

    testWidgets('tapping card without custom onTap opens TemplateDetailScreen', (tester) async {
      const template = ReactionTemplate(
        id: 'med-paracetamol-01',
        name: 'Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology',
        iupacName: '4-aminophenol + acetic anhydride → N-(4-hydroxyphenyl)acetamide + acetic acid',
        description: 'Foundational drug synthesis for Pharm-D students.',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '28\nReactants\nC 0 0 0\n',
        productXyz: '28\nProducts\nC 0 0 0\n',
        referenceEa: 14.5,
        doi: '10.1159/000136547',
        journalRef: 'Pharmacology 1974, 12, 251-260',
        tags: ['Pharm-D', 'Paracetamol'],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeNotifier()),
            Provider<AuthService>(create: (_) => LocalAuthService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 380,
                height: 255,
                child: ReactionCardWidget(
                  template: template,
                  onLoad: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Paracetamol (Acetaminophen) Synthesis & CYP2E1 Toxicology'));
      await tester.pumpAndSettle();

      // If user is unauthenticated, clicking requires authentication
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.textContaining('Sign in required'), findsOneWidget);
    });

    testWidgets('renders refined subfield tags and academic curriculum badges on cards', (tester) async {
      const cardioTemplate = ReactionTemplate(
        id: 'med-atorvastatin-01',
        name: 'Atorvastatin HMG-CoA Reductase Statin Pharmacokinetics',
        iupacName: 'Atorvastatin Active Metabolite • 36 frames',
        description: 'First-line statin therapy for LDL reduction in Cardiology and Pharm-D curricula.',
        category: ReactionCategory.pharmaceutical,
        reactantXyz: '',
        productXyz: '',
        referenceEa: 12.8,
        doi: '10.1056/NEJMoa012345',
        journalRef: 'N Engl J Med 2001',
        tags: ['Pharm-D', 'MBBS', 'Cardiology', 'Statin', 'HMG-CoA'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 255,
              child: ReactionCardWidget(
                template: cardioTemplate,
                onLoad: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Subfield tag: Cardiology with heart icon
      expect(find.text('❤️ Cardiology'), findsOneWidget);

      // Academic curriculum badges
      expect(find.text('MBBS'), findsOneWidget);
      expect(find.text('Pharm-D'), findsOneWidget);

      // Clean mechanism tags
      expect(find.text('#Statin'), findsOneWidget);
      expect(find.text('#HMG-CoA'), findsOneWidget);
    });
  });
}
