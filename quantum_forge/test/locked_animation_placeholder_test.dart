import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/services/shared_reaction_service.dart';
import 'package:quantum_forge/core/widgets/locked_animation_placeholder.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_preview_trajectory_generator.dart';
import 'package:quantum_forge/features/reaction_library/data/reaction_templates.dart';
import 'package:quantum_forge/features/reaction_library/presentation/widgets/publication/publication_header_card.dart';
import 'package:quantum_forge/features/reaction_runner/data/models/reaction_models.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/widgets/dashboard_cards/reaction_animation_card.dart';

void main() {
  group('LockedAnimationPlaceholder Widget Tests', () {
    testWidgets('renders title, subtitle, and action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LockedAnimationPlaceholder(
              title: '3D Trajectory Animation Locked',
              subtitle: 'Sign in to unlock interactive 3D trajectory playback.',
            ),
          ),
        ),
      );

      expect(find.text('3D Trajectory Animation Locked'), findsOneWidget);
      expect(
        find.text('Sign in to unlock interactive 3D trajectory playback.'),
        findsOneWidget,
      );
      expect(find.text('Sign In / Register'), findsOneWidget);
      expect(find.text('🧪 1-Click Demo Account'), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('calls onSignInRequested when Sign In button is tapped',
        (tester) async {
      bool signInCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockedAnimationPlaceholder(
              onSignInRequested: () {
                signInCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sign In / Register'));
      await tester.pump();

      expect(signInCalled, isTrue);
    });

    testWidgets('renders in compact mode for sub-viewers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LockedAnimationPlaceholder(
              compact: true,
              title: '3D Structure Viewer Locked',
              subtitle: 'Sign in to inspect distinct 3D molecular fragments.',
            ),
          ),
        ),
      );

      expect(find.text('3D Structure Viewer Locked'), findsOneWidget);
      expect(find.text('Sign In / Register'), findsOneWidget);
    });
  });

  group('ReactionAnimationCard Auth Gating Tests', () {
    testWidgets('renders LockedAnimationPlaceholder when isUserSignedIn is false',
        (tester) async {
      final status = ReactionStatusResponse(
        reactionId: 'rx-test-123',
        state: ReactionState.completed,
        progress: 1.0,
        trajectoryFrames: const ['3\n\nC 0 0 0\nH 1 0 0\nH -1 0 0'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReactionAnimationCard(
              status: status,
              isUserSignedIn: false,
            ),
          ),
        ),
      );

      expect(find.byType(LockedAnimationPlaceholder), findsOneWidget);
      expect(find.text('Sign-In Required'), findsOneWidget);
      expect(find.text('3D Trajectory Animation Locked'), findsOneWidget);
    });
  });

  group('Publication Sharing & Trajectory Tests', () {
    test('SharedReactionService.getPublicationShareUrl builds valid URL', () {
      final url = SharedReactionService.getPublicationShareUrl('diels_alder_classic');
      expect(url, contains('/?publication=diels_alder_classic'));
    });

    test('ReactionPreviewTrajectoryGenerator generates 121 frames and Eckart profile', () {
      final template = kReactionTemplates.first;
      final trajectory = ReactionPreviewTrajectoryGenerator.generateTrajectory(template);
      final profile = ReactionPreviewTrajectoryGenerator.generateEnergyProfile(template.referenceEa);

      expect(trajectory.length, equals(121));
      expect(profile.length, equals(121));
      expect(profile[ReactionPreviewTrajectoryGenerator.tsFrame], closeTo(template.referenceEa, 0.5));
    });

    testWidgets('PublicationHeaderCard renders Share Publication and triggers onShare',
        (tester) async {
      bool shareTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PublicationHeaderCard(
              title: 'Total Synthesis of Aspirin',
              authors: 'Felix Hoffmann',
              journal: 'Nature Chemistry',
              publisher: 'Springer Nature',
              year: '1897',
              doi: '10.1021/test.aspirin',
              onShare: () {
                shareTapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Share Publication'), findsOneWidget);
      await tester.tap(find.text('Share Publication'));
      await tester.pump();

      expect(shareTapped, isTrue);
    });
  });
}
