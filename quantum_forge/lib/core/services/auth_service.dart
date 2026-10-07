// ============================================================================
// AuthService — Abstract interface for identity management
// Implementations: LocalAuthService (UUID), FirebaseAuthService
// ============================================================================

abstract class AuthService {
  /// Returns a stable user identifier. Creates one on first call.
  Future<String> getUserId();

  /// True if the user has an active session.
  Future<bool> isAuthenticated();

  /// Sign out / clear session.
  Future<void> signOut();

  /// Sign in with email and password.
  Future<void> signIn(String email, String password);

  /// Sign up with email and password.
  Future<void> signUp(String email, String password);

  /// Sign in with Google.
  Future<void> signInWithGoogle();

  /// Sends a password-reset email to [email].
  ///
  /// Completes when the backend has accepted the request — not when the user
  /// actually resets. The reset itself happens on the link the user receives.
  ///
  /// Implementations that have no concept of a password (offline / UUID-only
  /// identity) should throw [UnsupportedError]; callers are expected to only
  /// surface the "Forgot password?" affordance when the active service can
  /// actually send mail.
  Future<void> sendPasswordResetEmail(String email);
}
