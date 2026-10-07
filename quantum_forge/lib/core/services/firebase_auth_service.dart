import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  /// Resolved per call, not per construction.
  ///
  /// This used to be `final FirebaseAuth _auth = FirebaseAuth.instance;`, which
  /// runs at construction — and `main()` constructs this before the app boots. If
  /// `Firebase.initializeApp` has not completed (a slow or blocked SDK, an
  /// offline machine), that initializer throws `[core/no-app]` and takes the whole
  /// boot down with it, which presents as a white screen. A getter moves the
  /// failure to the call that actually needs Firebase, where it can be reported.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Subscription to `authStateChanges()`.
  ///
  /// The listener exists so that a session restored on app start — the user
  /// signed in yesterday, opens the tab today — triggers a profile sync without
  /// requiring them to sign in again. Without this, the `users/{uid}` document
  /// would only be created when the user actively signed in during the current
  /// browser session.
  StreamSubscription<User?>? _authSub;

  /// Guards [_ensureListener] against double-attachment when several callers
  /// race (e.g. two `isAuthenticated()` probes in the same frame).
  bool _listenerAttached = false;

  /// Guards [_ensureLocalPersistence] against a redundant second call.
  bool _persistenceConfigured = false;

  /// Pins Firebase Auth to browser-local persistence on web.
  ///
  /// On mobile, persistence is always local and `setPersistence` is not
  /// implemented — hence the [kIsWeb] guard. On web the default is already
  /// LOCAL, but being explicit here means a future change to the default (or a
  /// stray `setPersistence(SESSION)` call elsewhere) can't silently downgrade
  /// the session to "cleared when the tab closes".
  Future<void> _ensureLocalPersistence() async {
    if (!kIsWeb) return;
    if (_persistenceConfigured) return;
    _persistenceConfigured = true;
    try {
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      // Not fatal — Firebase falls back to its own default, which is LOCAL.
      debugPrint('Could not set Firebase Auth persistence to LOCAL: $e');
    }
  }

  /// Attaches the auth-state listener exactly once per service instance.
  void _ensureListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;
    _authSub = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // Fire-and-forget: a slow or failing Firestore write must never delay
        // the UI's auth state transition.
        unawaited(_syncUserProfile(user));
      }
    });
  }

  /// Writes (or updates) `users/{uid}` with the current profile.
  ///
  /// Merges rather than overwrites, so fields written by other parts of the app
  /// (workspaces, preferences, saved reactions once they exist) are preserved.
  /// `createdAt` is only set the first time; `lastSeen` is bumped on every sync.
  ///
  /// Note: `photoURL` is deliberately not stored. The profile picture already
  /// lives in the Firebase Auth user record and is reachable via `user.photoURL`
  /// on every session — duplicating it in Firestore would just be a cache we'd
  /// have to keep in sync.
  Future<void> _syncUserProfile(User user) async {
    try {
      final docRef = _db.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      final data = <String, dynamic>{
        'uid': user.uid,
        'email': user.email,
        'displayName':
            user.displayName ??
            (user.email != null ? user.email!.split('@').first : null),
        'emailVerified': user.emailVerified,
        'lastSeen': FieldValue.serverTimestamp(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      // Never rethrow: a profile-sync failure must not break the sign-in flow.
      // The user stays signed in; the profile just won't be up to date.
      debugPrint('Firestore user profile sync failed: $e');
    }
  }

  @override
  Future<String> getUserId() async {
    _ensureListener();
    final user = _auth.currentUser;
    if (user != null) {
      unawaited(_syncUserProfile(user));
      return user.uid;
    }
    // Fallback if accessed before sign in, though ideally shouldn't happen.
    return '';
  }

  @override
  Future<bool> isAuthenticated() async {
    _ensureListener();
    final user = _auth.currentUser;
    if (user != null) {
      unawaited(_syncUserProfile(user));
    }
    return user != null;
  }

  @override
  Future<void> signIn(String email, String password) async {
    _ensureListener();
    await _ensureLocalPersistence();
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) {
      await _syncUserProfile(cred.user!);
    }
  }

  @override
  Future<void> signUp(String email, String password) async {
    _ensureListener();
    await _ensureLocalPersistence();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) {
      await _syncUserProfile(cred.user!);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> signInWithGoogle() async {
    _ensureListener();
    await _ensureLocalPersistence();
    final googleProvider = GoogleAuthProvider();
    final cred = await _auth.signInWithPopup(googleProvider);
    if (cred.user != null) {
      await _syncUserProfile(cred.user!);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    _ensureListener();
    // Note: for security, Firebase deliberately succeeds even when the address
    // is not registered — it does not tell the caller whether an account
    // exists. The UI reports the same generic "link sent" either way.
    await _auth.sendPasswordResetEmail(email: email);
  }
}
