import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_forge/core/state/quantum_provider.dart';
import 'package:quantum_forge/core/services/auth_service.dart';
import 'package:quantum_forge/core/services/local_auth_service.dart';
import 'package:quantum_forge/core/theme/theme_provider.dart';
import 'package:quantum_forge/screens/auth_screen.dart';

void main() {
  testWidgets('AuthScreen renders AutofillGroup and Password Manager hints', (tester) async {
    bool loginSuccessCalled = false;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          Provider<AuthService>(create: (_) => LocalAuthService()),
        ],
        child: MaterialApp(
          home: AuthScreen(
            onLoginSuccess: () {
              loginSuccessCalled = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AutofillGroup is present for password managers
    expect(find.byType(AutofillGroup), findsOneWidget);

    // Verify Email and Password TextFields are present
    expect(find.byType(TextField), findsNWidgets(2));

    // Verify Password Manager trust indicator is present
    expect(
      find.textContaining('Google Password Manager, Apple iCloud Keychain, and Windows Passkeys'),
      findsOneWidget,
    );

    // Verify Passkey action button is displayed
    expect(find.textContaining('Passkey'), findsWidgets);
    expect(loginSuccessCalled, isFalse);
  });

  testWidgets('AuthScreen toggles to Create Account and shows newPassword hint', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          Provider<AuthService>(create: (_) => LocalAuthService()),
        ],
        child: const MaterialApp(
          home: AuthScreen(
            onLoginSuccess: _dummySuccess,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Create Account tab
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Now 3 fields should be present (Name, Email, Password)
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Full Name / Research Lab'), findsOneWidget);

    // Verify Register Passkey option is visible in Sign-Up mode
    expect(find.textContaining('Register'), findsWidgets);
  });
}

void _dummySuccess() {}
