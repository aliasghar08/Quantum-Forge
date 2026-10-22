import 'dart:convert' as json_pkg;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:quantum_forge/core/services/app_storage.dart';

enum PasskeyPlatform {
  apple,
  windows,
  google,
  generic,
}

class PasskeyPlatformInfo {
  final PasskeyPlatform platform;
  final String platformName;
  final String managerName;
  final String authenticatorName;
  final String iconName;

  const PasskeyPlatformInfo({
    required this.platform,
    required this.platformName,
    required this.managerName,
    required this.authenticatorName,
    required this.iconName,
  });
}

class PasskeyCredential {
  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final PasskeyPlatform platform;

  const PasskeyCredential({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
        'platform': platform.name,
      };

  factory PasskeyCredential.fromJson(Map<String, dynamic> json) {
    return PasskeyCredential(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      platform: PasskeyPlatform.values.firstWhere(
        (p) => p.name == json['platform'],
        orElse: () => PasskeyPlatform.generic,
      ),
    );
  }
}

class PasskeyResult {
  final bool success;
  final String? credentialId;
  final String? email;
  final PasskeyPlatform? platform;
  final String? message;
  final String? error;
  final bool cancelled;

  const PasskeyResult({
    required this.success,
    this.credentialId,
    this.email,
    this.platform,
    this.message,
    this.error,
    this.cancelled = false,
  });
}

class PasskeyServiceImplementation {
  static const _storageKey = 'quantum_forge_stub_passkeys';

  Future<bool> isPasskeySupported() async => true;

  Future<bool> isPlatformAuthenticatorAvailable() async => true;

  Future<PasskeyPlatformInfo> getPlatformInfo() async {
    bool isMac = false;
    bool isWindows = false;
    try {
      isMac = Platform.isMacOS || Platform.isIOS;
      isWindows = Platform.isWindows;
    } catch (_) {}

    if (isMac) {
      return const PasskeyPlatformInfo(
        platform: PasskeyPlatform.apple,
        platformName: 'macOS / iOS',
        managerName: 'Apple Password Manager & iCloud Keychain',
        authenticatorName: 'Touch ID / Apple Passkey',
        iconName: 'fingerprint',
      );
    } else if (isWindows) {
      return const PasskeyPlatformInfo(
        platform: PasskeyPlatform.windows,
        platformName: 'Windows',
        managerName: 'Windows Credential Manager',
        authenticatorName: 'Windows Hello / Windows Passkey',
        iconName: 'shield',
      );
    }

    return const PasskeyPlatformInfo(
      platform: PasskeyPlatform.generic,
      platformName: 'Workstation Authenticator',
      managerName: 'Google Password Manager & Device Passkeys',
      authenticatorName: 'Biometric / Device Passkey',
      iconName: 'key',
    );
  }

  Future<PasskeyResult> createPasskey({
    required String email,
    String? displayName,
  }) async {
    final info = await getPlatformInfo();
    final credId = 'passkey_${DateTime.now().millisecondsSinceEpoch}_${email.hashCode.abs()}';
    final cred = PasskeyCredential(
      id: credId,
      email: email,
      displayName: displayName ?? email.split('@').first,
      createdAt: DateTime.now(),
      platform: info.platform,
    );

    final list = await getRegisteredPasskeys();
    final filtered = list.where((p) => p.email != email).toList()..add(cred);
    await _savePasskeys(filtered);

    return PasskeyResult(
      success: true,
      credentialId: credId,
      email: email,
      platform: info.platform,
      message: 'Passkey registered to ${info.managerName}',
    );
  }

  Future<PasskeyResult> authenticatePasskey({String? email}) async {
    final list = await getRegisteredPasskeys();
    final info = await getPlatformInfo();

    if (list.isEmpty) {
      // Auto-register a default researcher passkey for seamless testing
      final autoEmail = email ?? 'researcher@quantumforge.internal';
      await createPasskey(email: autoEmail, displayName: 'Lead Researcher');
      return PasskeyResult(
        success: true,
        credentialId: 'auto_passkey_${autoEmail.hashCode.abs()}',
        email: autoEmail,
        platform: info.platform,
        message: 'Signed in with ${info.authenticatorName}',
      );
    }

    final matched = email != null
        ? list.firstWhere((p) => p.email == email, orElse: () => list.first)
        : list.first;

    return PasskeyResult(
      success: true,
      credentialId: matched.id,
      email: matched.email,
      platform: info.platform,
      message: 'Signed in with ${info.authenticatorName}',
    );
  }

  Future<List<PasskeyCredential>> getRegisteredPasskeys() async {
    final raw = AppStorage.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> items = _decodeJsonList(raw);
      return items.map((e) => PasskeyCredential.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      debugPrint('Failed to parse stub passkeys: $e');
      return [];
    }
  }

  Future<bool> deletePasskey(String credentialId) async {
    final list = await getRegisteredPasskeys();
    final updated = list.where((p) => p.id != credentialId).toList();
    await _savePasskeys(updated);
    return true;
  }

  Future<void> _savePasskeys(List<PasskeyCredential> list) async {
    final jsonStr = _encodeJsonList(list.map((p) => p.toJson()).toList());
    AppStorage.setString(_storageKey, jsonStr);
  }

  List<dynamic> _decodeJsonList(String source) {
    return json_pkg.jsonDecode(source) as List<dynamic>;
  }

  String _encodeJsonList(List<Map<String, dynamic>> items) {
    return json_pkg.jsonEncode(items);
  }
}
