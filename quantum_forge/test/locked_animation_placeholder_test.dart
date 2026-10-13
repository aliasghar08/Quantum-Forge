import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/widgets/locked_animation_placeholder.dart';
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
      expect(find.text('🧪 1-Click Demo Account'), findsOneWidget);
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
}
