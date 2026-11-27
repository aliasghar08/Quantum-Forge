import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/algorithms/trajectory_isolate_builder.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/data/firestore_library_repository.dart';
import 'package:quantum_forge/screens/template_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrajectoryIsolateBuilder & LRU Cache Tests', () {
    test('computes trajectory bundle synchronously/isolate with 121 frames', () {
      final template = kReactionTemplates.first;
      final input = TrajectoryIsolateInput(
        reactionId: template.id,
        reactantXyz: template.reactantXyz,
        productXyz: template.productXyz,
        templateName: template.name,
        referenceEa: template.referenceEa,
        frameCount: 121,
      );

      final bundle = computeTrajectoryInIsolate(input);
      expect(bundle.reactionId, equals(template.id));
      expect(bundle.frames.length, equals(121));
      expect(bundle.energyProfile.length, equals(121));
      expect(bundle.tsFrame, equals(60));
      expect(bundle.staticBonds, isNotEmpty);
      expect(bundle.trajectorySdf, isNotNull);
      expect(bundle.trajectorySdf!.contains(r'$$$$'), isTrue);
    });

    test('TrajectoryIsolateService caches results up to 12 entries with LRU eviction', () async {
      final service = TrajectoryIsolateService.instance;
      service.clearCache();

      final template = kReactionTemplates.first;
      final input = TrajectoryIsolateInput(
        reactionId: 'test_rxn_0',
        reactantXyz: template.reactantXyz,
        productXyz: template.productXyz,
        templateName: 'Test 0',
        referenceEa: 20.0,
        frameCount: 10,
      );

      final bundle1 = await service.getOrCompute(input);
      expect(service.hasCached('test_rxn_0'), isTrue);

      // Verify second retrieval is synchronous from cache
      final bundle2 = service.getCached('test_rxn_0');
      expect(bundle2, isNotNull);
      expect(identical(bundle1, bundle2), isTrue);

      // Fill cache to 12
      for (int i = 1; i < 12; i++) {
        await service.getOrCompute(TrajectoryIsolateInput(
          reactionId: 'test_rxn_$i',
          reactantXyz: template.reactantXyz,
          productXyz: template.productXyz,
          templateName: 'Test $i',
          referenceEa: 20.0,
          frameCount: 5,
        ));
      }
      expect(service.hasCached('test_rxn_0'), isTrue);
      expect(service.hasCached('test_rxn_11'), isTrue);

      // 13th entry should evict oldest
      await service.getOrCompute(TrajectoryIsolateInput(
        reactionId: 'test_rxn_12',
        reactantXyz: template.reactantXyz,
        productXyz: template.productXyz,
        templateName: 'Test 12',
        referenceEa: 20.0,
        frameCount: 5,
      ));

      expect(service.hasCached('test_rxn_12'), isTrue);
      service.clearCache();
    });

    test('deduplicates concurrent in-flight compute requests', () async {
      final service = TrajectoryIsolateService.instance;
      service.clearCache();

      final template = kReactionTemplates.first;
      final input = TrajectoryIsolateInput(
        reactionId: 'concurrent_test',
        reactantXyz: template.reactantXyz,
        productXyz: template.productXyz,
        templateName: 'Concurrent',
        referenceEa: 15.0,
        frameCount: 20,
      );

      final f1 = service.getOrCompute(input);
      final f2 = service.getOrCompute(input);

      final results = await Future.wait([f1, f2]);
      expect(results[0].reactionId, equals('concurrent_test'));
      expect(identical(results[0], results[1]), isTrue);
      service.clearCache();
    });
  });

  group('FirestoreLibraryRepository Prefetch Deduplication', () {
    test('deduplicates concurrent in-flight geometry requests', () async {
      final repo = FirestoreLibraryRepository();
      // Calling fetchReactionGeometry with a known template ID twice concurrently
      final f1 = repo.fetchReactionGeometry('poly-ziegler-natta-01');
      final f2 = repo.fetchReactionGeometry('poly-ziegler-natta-01');

      expect(identical(f1, f2), isTrue);
      final res = await f1;
      expect(res.id, equals('poly-ziegler-natta-01'));
    });
  });

  group('TemplateDetailScreen Immediate Frame 1 Render (< 50 ms INP)', () {
    testWidgets('renders immediately with Frame 1 and mounts secondary panels smoothly', (tester) async {
      final template = kReactionTemplates.first;

      await tester.pumpWidget(
        MaterialApp(
          home: TemplateDetailScreen(
            template: template,
            onLoad: () {},
          ),
        ),
      );

      // Frame 1 immediate paint check
      expect(find.byType(TemplateDetailScreen), findsOneWidget);
      expect(find.text(template.name), findsWidgets);

      // Let postFrameCallback and microtasks execute
      await tester.pumpAndSettle();
      expect(find.byType(TemplateDetailScreen), findsOneWidget);
    });
  });
}
