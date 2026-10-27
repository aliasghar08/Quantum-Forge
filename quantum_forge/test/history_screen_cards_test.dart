import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/reaction_card_widget.dart';

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
  });
}
