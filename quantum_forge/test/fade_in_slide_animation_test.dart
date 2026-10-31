import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/animations/fade_in_slide_animation.dart';

void main() {
  testWidgets('FadeInSlideAnimation renders child and advances animation',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeInSlideAnimation(
            duration: Duration(milliseconds: 300),
            child: Text('Animated Element'),
          ),
        ),
      ),
    );

    expect(find.text('Animated Element'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Animated Element'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Animated Element'), findsOneWidget);
  });

  testWidgets('FadeInSlideAnimation handles index-based delay', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeInSlideAnimation(
            index: 2,
            delayStepMs: 50,
            duration: Duration(milliseconds: 200),
            child: Text('Delayed Element'),
          ),
        ),
      ),
    );

    expect(find.text('Delayed Element'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Delayed Element'), findsOneWidget);
  });
}

