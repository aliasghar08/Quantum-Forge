// ============================================================================
// PasskeyService — Cross-platform WebAuthn & Passkey Service
// Supports Apple iCloud Keychain & Touch ID (macOS/iOS),
// Windows Hello & Windows Credential Manager (Windows),
// and Google Password Manager Passkeys (Chrome / Android).
// ============================================================================

import 'passkey_service_stub.dart'
    if (dart.library.js_interop) 'passkey_service_web.dart';

export 'passkey_service_stub.dart'
    if (dart.library.js_interop) 'passkey_service_web.dart'
    show PasskeyPlatform, PasskeyPlatformInfo, PasskeyCredential, PasskeyResult;

class PasskeyService {
  PasskeyService._();
  static final PasskeyService instance = PasskeyService._();

  final PasskeyServiceImplementation _impl = PasskeyServiceImplementation();

  /// Whether WebAuthn / Passkeys is supported in the current environment.
  Future<bool> isPasskeySupported() => _impl.isPasskeySupported();

  /// Whether a platform authenticator (Apple Touch ID, Windows Hello, etc.) is available.
  Future<bool> isPlatformAuthenticatorAvailable() => _impl.isPlatformAuthenticatorAvailable();

  /// Resolves detailed metadata about the current OS / password manager platform.
  Future<PasskeyPlatformInfo> getPlatformInfo() => _impl.getPlatformInfo();

  /// Creates and registers a new Passkey tied to the user's email.
  Future<PasskeyResult> registerPasskey({
    required String email,
    String? displayName,
  }) =>
      _impl.createPasskey(email: email, displayName: displayName);

  /// Authenticates using the native platform passkey / biometric prompt.
  Future<PasskeyResult> authenticatePasskey({String? email}) =>
      _impl.authenticatePasskey(email: email);

  /// Returns all passkeys registered locally on this workstation.
  Future<List<PasskeyCredential>> getRegisteredPasskeys() =>
      _impl.getRegisteredPasskeys();

  /// Deletes a registered passkey from this device.
  Future<bool> deletePasskey(String credentialId) =>
      _impl.deletePasskey(credentialId);
}
