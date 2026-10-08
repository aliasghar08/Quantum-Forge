// ============================================================================
// AuthGate — routes between AuthScreen and DashboardScreen based on Firebase
// Auth state, and waits for the *restored* session before deciding.
//
// Why this exists:
//
// Firebase Auth on web persists sessions in localStorage by default. When the
// user comes back to the app, Firebase restores their session from that cache —
// but the restore is asynchronous, and `Firebase.initializeApp` itself is only
// kicked off *after* `runApp` (see the comment in main.dart: doing it before
// runApp risks a permanent white screen if the SDK fetch hangs).
//
// The net effect, before this widget existed: on a fresh page load, the app
// immediately rendered DashboardScreen (or AuthScreen), and whichever one it
// picked, it did so *before* Firebase had restored the persisted user. A
// returning user briefly saw the sign-in form, and depending on how the
// dashboard decides to check auth, could get stuck there until they signed in
// again. Setting the persistence mode alone does not fix that — the persistence
// was always set; the missing piece was waiting for the restore to complete.
//
// AuthGate closes that gap: it waits for FirebaseAuth.instance to be available
// (bounded), subscribes to `authStateChanges()` — which emits the restored user
// (or null) as its first event — and only then routes.
// ============================================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:quantum_forge/features/auth/presentation/screens/auth_screen.dart';
import 'package:quantum_forge/features/reaction_runner/presentation/screens/dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  /// How long to wait for Firebase to become available before giving up and
  /// showing the sign-in form. This bounds the "stuck on spinner" case when
  /// the SDK fails to load (offline, blocked CDN) — the app falls through to
  /// the offline-usable path rather than hanging forever.
  static const Duration firebaseWaitTimeout = Duration(seconds: 20);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _ready = false;
  User? _user;
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // 1. Wait for Firebase to be available. Firebase is initialized in a
    //    fire-and-forget call from main(), so the first few hundred
    //    milliseconds after runApp may see it uninitialized.
    final deadline = DateTime.now().add(AuthGate.firebaseWaitTimeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        // Touching .instance throws if Firebase isn't initialized yet.
        FirebaseAuth.instance;
        break;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }

    if (!mounted) return;

    // 2. Subscribe to auth state. On web, the first emission from
    //    authStateChanges() is the user restored from localStorage, or null
    //    if nothing was persisted. Either way it arrives here before we route.
    try {
      _sub = FirebaseAuth.instance.authStateChanges().listen(
        (user) {
          if (!mounted) return;
          setState(() {
            _user = user;
            _ready = true;
          });
        },
        onError: (Object e) {
          debugPrint('authStateChanges error: $e');
          if (!mounted) return;
          setState(() {
            _user = null;
            _ready = true;
          });
        },
      );
    } catch (e) {
      // Firebase unavailable — treat as signed out. The sign-in form will
      // surface a real error if the user tries to use it.
      debugPrint('FirebaseAuth unavailable in AuthGate: $e');
      if (!mounted) return;
      setState(() {
        _user = null;
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_user == null) {
      // The stream drives the transition once sign-in succeeds; the callback
      // is a no-op so we don't need to navigate manually.
      return AuthScreen(onLoginSuccess: _noop);
    }
    return const DashboardScreen();
  }
}

void _noop() {}